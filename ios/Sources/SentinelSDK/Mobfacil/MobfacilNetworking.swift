import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
#if canImport(Network)
import Network
import Security
#endif

/// Resolves domain names to IP addresses with automatic fallback for problematic CNAME chains.
public protocol MobfacilDNSResolver: Sendable {
    func resolve(host: String) async throws -> [String]
}

/// Default DNS resolver that resolves via system DNS, falling back to a static IP on failure
/// (e.g. Brazilian .com.br CNAME delegations failing on international carriers).
public final class DefaultMobfacilDNSResolver: MobfacilDNSResolver {
    public let fallbackMapping: [String: String]
    private let systemResolver: (@Sendable (String) throws -> [String])?

    public init(
        fallbackMapping: [String: String] = [
            MobfacilAuthConfig.defaultFallbackHost: MobfacilAuthConfig.defaultFallbackIP
        ],
        systemResolver: (@Sendable (String) throws -> [String])? = nil
    ) {
        self.fallbackMapping = fallbackMapping
        self.systemResolver = systemResolver
    }

    public func resolve(host: String) async throws -> [String] {
        // Attempt system DNS resolution first
        do {
            if let customResolver = systemResolver {
                let ips = try customResolver(host)
                if !ips.isEmpty {
                    return ips
                }
            } else {
                let ips = try Self.resolveUsingGetAddrInfo(host: host)
                if !ips.isEmpty {
                    return ips
                }
            }
        } catch {
            // System DNS failed - check fallback mapping
            if let fallbackIP = fallbackMapping[host] {
                return [fallbackIP]
            }
            throw MobfacilAuthError.dnsResolutionFailed(host: host)
        }

        // If no IPs were returned, check fallback
        if let fallbackIP = fallbackMapping[host] {
            return [fallbackIP]
        }
        throw MobfacilAuthError.dnsResolutionFailed(host: host)
    }

    private static func resolveUsingGetAddrInfo(host: String) throws -> [String] {
        var hints = addrinfo(
            ai_flags: AI_ADDRCONFIG,
            ai_family: AF_UNSPEC,
            ai_socktype: SOCK_STREAM,
            ai_protocol: 0,
            ai_addrlen: 0,
            ai_canonname: nil,
            ai_addr: nil,
            ai_next: nil
        )

        var res: UnsafeMutablePointer<addrinfo>?
        let status = getaddrinfo(host, nil, &hints, &res)
        defer {
            if res != nil {
                freeaddrinfo(res)
            }
        }

        guard status == 0, let first = res else {
            throw MobfacilAuthError.dnsResolutionFailed(host: host)
        }

        var addresses: [String] = []
        var ptr: UnsafeMutablePointer<addrinfo>? = first
        while let current = ptr {
            var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
            if current.pointee.ai_family == AF_INET {
                let addr = current.pointee.ai_addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                var sinAddr = addr.sin_addr
                inet_ntop(AF_INET, &sinAddr, &buffer, socklen_t(INET_ADDRSTRLEN))
                addresses.append(String(cString: buffer))
            } else if current.pointee.ai_family == AF_INET6 {
                let addr = current.pointee.ai_addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }
                var sin6Addr = addr.sin6_addr
                inet_ntop(AF_INET6, &sin6Addr, &buffer, socklen_t(INET6_ADDRSTRLEN))
                addresses.append(String(cString: buffer))
            }
            ptr = current.pointee.ai_next
        }

        return addresses
    }
}

/// HTTP network transport abstraction for testability and resilient fallback.
public protocol MobfacilHTTPTransport: Sendable {
    func execute(request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

/// Protocol for raw socket transports capable of connecting to fallback IPs with SNI.
public protocol MobfacilSocketTransportProtocol: Sendable {
    func executeWithFallback(
        request: URLRequest,
        fallbackIP: String,
        sniHost: String
    ) async throws -> (Data, HTTPURLResponse)
}

/// Fallback socket transport executing HTTP/1.1 requests directly over TLS with custom SNI,
/// routing directly to the fallback IP when DNS resolution fails.
public final class MobfacilSocketTransport: MobfacilSocketTransportProtocol {
    public init() {}

    /// Executes an HTTP request to the designated fallback IP while preserving the original SNI hostname.
    public func executeWithFallback(
        request: URLRequest,
        fallbackIP: String,
        sniHost: String
    ) async throws -> (Data, HTTPURLResponse) {
        #if canImport(Network)
        guard let url = request.url else {
            throw MobfacilAuthError.networkError("Invalid URL in fallback request")
        }

        let port: UInt16 = UInt16(url.port ?? (url.scheme == "http" ? 80 : 443))
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(fallbackIP),
            port: NWEndpoint.Port(integerLiteral: port)
        )

        let isTLS = (url.scheme?.lowercased() == "https")
        let parameters: NWParameters
        if isTLS {
            let tlsOptions = NWProtocolTLS.Options()
            sec_protocol_options_set_tls_server_name(tlsOptions.securityProtocolOptions, sniHost)
            let tcpOptions = NWProtocolTCP.Options()
            parameters = NWParameters(tls: tlsOptions, tcp: tcpOptions)
        } else {
            parameters = NWParameters.tcp
        }

        let connection = NWConnection(to: endpoint, using: parameters)

        return try await withCheckedThrowingContinuation { continuation in
            let queue = DispatchQueue(label: "com.sentinel.mobfacil.socket")
            var hasResumed = false

            func resumeOnce(with result: Result<(Data, HTTPURLResponse), Error>) {
                queue.sync {
                    guard !hasResumed else { return }
                    hasResumed = true
                    connection.cancel()
                    continuation.resume(with: result)
                }
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let rawRequest = Self.buildRawHTTPRequest(request: request, sniHost: sniHost)
                    connection.send(content: rawRequest, completion: .contentProcessed({ sendError in
                        if let sendError = sendError {
                            resumeOnce(with: .failure(MobfacilAuthError.networkError("Socket send error: \(sendError)")))
                            return
                        }
                        Self.readFullResponse(connection: connection, originalURL: url) { result in
                            resumeOnce(with: result)
                        }
                    }))
                case .failed(let error):
                    resumeOnce(with: .failure(MobfacilAuthError.networkError("Socket connection failed: \(error)")))
                case .cancelled:
                    resumeOnce(with: .failure(MobfacilAuthError.cancelled))
                default:
                    break
                }
            }

            connection.start(queue: queue)
        }
        #else
        throw MobfacilAuthError.networkError("Network framework not available on this platform")
        #endif
    }

    #if canImport(Network)
    private static func buildRawHTTPRequest(request: URLRequest, sniHost: String) -> Data {
        let method = request.httpMethod ?? "GET"
        let path = (request.url?.path.isEmpty == false ? request.url!.path : "/")
        let query = request.url?.query.map { "?\($0)" } ?? ""
        let fullPath = path + query

        var headers = "Host: \(sniHost)\r\n"
        headers += "Connection: close\r\n"

        if let allHeaders = request.allHTTPHeaderFields {
            for (key, val) in allHeaders where key.lowercased() != "host" && key.lowercased() != "connection" {
                headers += "\(key): \(val)\r\n"
            }
        }

        let body = request.httpBody ?? Data()
        if !body.isEmpty && request.value(forHTTPHeaderField: "Content-Length") == nil {
            headers += "Content-Length: \(body.count)\r\n"
        }

        var raw = "\(method) \(fullPath) HTTP/1.1\r\n\(headers)\r\n"
        var data = raw.data(using: .utf8) ?? Data()
        data.append(body)
        return data
    }

    private static func readFullResponse(
        connection: NWConnection,
        originalURL: URL,
        completion: @escaping (Result<(Data, HTTPURLResponse), Error>) -> Void
    ) {
        var accumulatedData = Data()

        func receiveNext() {
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { content, _, isComplete, error in
                if let content = content {
                    accumulatedData.append(content)
                }

                if let error = error {
                    completion(.failure(MobfacilAuthError.networkError("Socket receive error: \(error)")))
                    return
                }

                if isComplete || (content == nil && error == nil) {
                    do {
                        let parsed = try Self.parseHTTPResponse(data: accumulatedData, url: originalURL)
                        completion(.success(parsed))
                    } catch {
                        completion(.failure(error))
                    }
                    return
                }

                receiveNext()
            }
        }

        receiveNext()
    }

    private static func parseHTTPResponse(data: Data, url: URL) throws -> (Data, HTTPURLResponse) {
        guard let headerTerminatorRange = data.range(of: Data("\r\n\r\n".utf8)) else {
            throw MobfacilAuthError.decodingError("Invalid HTTP socket response: header terminator not found")
        }

        let headerData = data.subdata(in: 0..<headerTerminatorRange.lowerBound)
        let bodyData = data.subdata(in: headerTerminatorRange.upperBound..<data.count)

        guard let headerString = String(data: headerData, encoding: .utf8) else {
            throw MobfacilAuthError.decodingError("Invalid HTTP header encoding")
        }

        let lines = headerString.components(separatedBy: "\r\n")
        guard let statusLine = lines.first else {
            throw MobfacilAuthError.decodingError("Empty HTTP status line")
        }

        let statusParts = statusLine.components(separatedBy: " ")
        guard statusParts.count >= 2, let statusCode = Int(statusParts[1]) else {
            throw MobfacilAuthError.decodingError("Failed to parse HTTP status code from line: \(statusLine)")
        }

        var headerFields: [String: String] = [:]
        for line in lines.dropFirst() {
            let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
            if parts.count == 2 {
                headerFields[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
            }
        }

        guard let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: statusParts[0],
            headerFields: headerFields
        ) else {
            throw MobfacilAuthError.networkError("Failed to initialize HTTPURLResponse")
        }

        return (bodyData, response)
    }
    #endif
}

/// Standard production HTTP transport with built-in international DNS fallback.
public final class DefaultMobfacilHTTPTransport: MobfacilHTTPTransport {
    private let config: MobfacilAuthConfig
    private let session: URLSession
    private let dnsResolver: MobfacilDNSResolver
    private let socketTransport: any MobfacilSocketTransportProtocol

    public init(
        config: MobfacilAuthConfig,
        session: URLSession = .shared,
        dnsResolver: MobfacilDNSResolver? = nil,
        socketTransport: any MobfacilSocketTransportProtocol = MobfacilSocketTransport()
    ) {
        self.config = config
        self.session = session
        self.dnsResolver = dnsResolver ?? DefaultMobfacilDNSResolver(
            fallbackMapping: [config.dnsFallbackHost: config.dnsFallbackIP]
        )
        self.socketTransport = socketTransport
    }

    public func execute(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MobfacilAuthError.networkError("Response was not an HTTPURLResponse")
            }
            return (data, httpResponse)
        } catch let urlError as URLError where isHostResolutionError(urlError) {
            guard config.dnsFallbackEnabled,
                  let host = request.url?.host,
                  host == config.dnsFallbackHost else {
                throw urlError
            }

            // Fallback to IP while preserving SNI
            return try await socketTransport.executeWithFallback(
                request: request,
                fallbackIP: config.dnsFallbackIP,
                sniHost: host
            )
        } catch let nsError as NSError where isHostResolutionNSError(nsError) {
            guard config.dnsFallbackEnabled,
                  let host = request.url?.host,
                  host == config.dnsFallbackHost else {
                throw nsError
            }

            return try await socketTransport.executeWithFallback(
                request: request,
                fallbackIP: config.dnsFallbackIP,
                sniHost: host
            )
        }
    }

    private func isHostResolutionError(_ error: URLError) -> Bool {
        return error.code == .cannotFindHost ||
               error.code == .dnsLookupFailed ||
               error.code.rawValue == -1003
    }

    private func isHostResolutionNSError(_ error: NSError) -> Bool {
        return error.domain == NSURLErrorDomain && (error.code == -1003 || error.code == -1004)
    }
}

/// Mock HTTP transport for unit testing authentication, renewals, 401 retries, and errors.
public final class MockMobfacilHTTPTransport: MobfacilHTTPTransport, @unchecked Sendable {
    public typealias RequestHandler = (URLRequest) throws -> (Data, HTTPURLResponse)

    private let lock = NSLock()
    private var handlers: [String: RequestHandler] = [:]
    private var defaultHandler: RequestHandler?
    private var executedRequestsList: [URLRequest] = []

    public init(defaultHandler: RequestHandler? = nil) {
        self.defaultHandler = defaultHandler
    }

    public func registerHandler(forPath path: String, handler: @escaping RequestHandler) {
        lock.lock()
        defer { lock.unlock() }
        handlers[path] = handler
    }

    public func setDefaultHandler(_ handler: @escaping RequestHandler) {
        lock.lock()
        defer { lock.unlock() }
        defaultHandler = handler
    }

    public var executedRequests: [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return executedRequestsList
    }

    public func resetExecutedRequests() {
        lock.lock()
        defer { lock.unlock() }
        executedRequestsList.removeAll()
    }

    public func execute(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lock.lock()
        executedRequestsList.append(request)
        let path = request.url?.path ?? ""
        let matchingHandler = handlers[path] ?? defaultHandler
        lock.unlock()

        guard let handler = matchingHandler else {
            throw MobfacilAuthError.networkError("No mock handler registered for request: \(request.url?.absoluteString ?? "")")
        }

        return try handler(request)
    }
}
