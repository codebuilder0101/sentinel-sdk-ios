import Foundation

/// Service coordinating telemetry payload serialization, Bearer token header injection,
/// KrakenD gateway transmission, and the Flow 2 Alt (401 Retry) recovery loop.
public final class MobfacilCollectorService: Sendable {
    public let config: MobfacilAuthConfig
    public let tokenManager: MobfacilTokenManager
    private let transport: MobfacilHTTPTransport

    public init(
        config: MobfacilAuthConfig = MobfacilAuthConfig(),
        tokenManager: MobfacilTokenManager? = nil,
        transport: MobfacilHTTPTransport? = nil
    ) {
        self.config = config
        let resolvedTransport = transport ?? DefaultMobfacilHTTPTransport(config: config)
        self.transport = resolvedTransport
        self.tokenManager = tokenManager ?? MobfacilTokenManager(config: config, transport: resolvedTransport)
    }

    /// Transmits a SentinelPayload containing device telemetry, personal data, and security signatures.
    public func transmit(payload: SentinelPayload, endpoint: String? = nil) async throws -> MobfacilCollectorResponse {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(payload)
        return try await transmit(rawJSONData: data, endpoint: endpoint)
    }

    /// Transmits a raw JSON string to the telemetry collector endpoint.
    public func transmit(jsonString: String, endpoint: String? = nil) async throws -> MobfacilCollectorResponse {
        guard let data = jsonString.data(using: .utf8) else {
            throw MobfacilAuthError.decodingError("Invalid UTF-8 string payload")
        }
        return try await transmit(rawJSONData: data, endpoint: endpoint)
    }

    /// Transmits any Encodable data structure to the telemetry collector endpoint.
    public func transmit<T: Encodable>(data: T, endpoint: String? = nil) async throws -> MobfacilCollectorResponse {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encodedData = try encoder.encode(data)
        return try await transmit(rawJSONData: encodedData, endpoint: endpoint)
    }

    /// Transmits raw JSON data with Bearer token authentication and 401 retry handling.
    public func transmit(rawJSONData: Data, endpoint: String? = nil) async throws -> MobfacilCollectorResponse {
        let targetURL = resolveTargetURL(endpoint: endpoint)

        // 1. Acquire valid token (Flow 1 / Flow 3)
        let token = try await tokenManager.getValidToken()

        // 2. Prepare HTTP request (Flow 2)
        var request = URLRequest(url: targetURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("\(token.tokenType) \(token.accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = rawJSONData
        request.timeoutInterval = config.requestTimeout

        // 3. Transmit payload
        let (data, response) = try await transport.execute(request: request)

        // 4. Handle 200..299 Success
        if (200...299).contains(response.statusCode) {
            return parseSuccessResponse(data: data, response: response)
        }

        // 5. Handle Flow 2 Alt: 401 Unauthorized (Token expired in flight)
        if response.statusCode == 401 {
            // Invalidate cached token immediately
            try await tokenManager.invalidateToken()

            // Force fresh token renewal
            let freshToken = try await tokenManager.getValidToken(forceRefresh: true)

            // Retry data transmission once with new Bearer token
            var retryRequest = request
            retryRequest.setValue("\(freshToken.tokenType) \(freshToken.accessToken)", forHTTPHeaderField: "Authorization")

            let (retryData, retryResponse) = try await transport.execute(request: retryRequest)

            if (200...299).contains(retryResponse.statusCode) {
                return parseSuccessResponse(data: retryData, response: retryResponse)
            } else {
                let errorBody = String(data: retryData, encoding: .utf8)
                throw MobfacilAuthError.httpError(statusCode: retryResponse.statusCode, body: errorBody)
            }
        }

        // 6. Other non-2xx status codes
        let errorBody = String(data: data, encoding: .utf8)
        throw MobfacilAuthError.httpError(statusCode: response.statusCode, body: errorBody)
    }

    // MARK: - Private Helpers

    private func resolveTargetURL(endpoint: String?) -> URL {
        guard let custom = endpoint else {
            return config.fullDataURL
        }

        if custom.hasPrefix("http://") || custom.hasPrefix("https://"),
           let absolute = URL(string: custom) {
            return absolute
        }

        return URL(string: custom, relativeTo: config.baseUrl)?.absoluteURL ?? config.baseUrl.appendingPathComponent(custom)
    }

    private func parseSuccessResponse(data: Data, response: HTTPURLResponse) -> MobfacilCollectorResponse {
        if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let trackingId = jsonObject["tracking_id"] as? String ?? jsonObject["id"] as? String
            let message = jsonObject["message"] as? String ?? jsonObject["status"] as? String
            return MobfacilCollectorResponse(
                statusCode: response.statusCode,
                success: true,
                trackingId: trackingId,
                message: message,
                timestamp: Date(),
                rawData: data
            )
        }

        return MobfacilCollectorResponse(
            statusCode: response.statusCode,
            success: true,
            trackingId: nil,
            message: nil,
            timestamp: Date(),
            rawData: data
        )
    }
}
