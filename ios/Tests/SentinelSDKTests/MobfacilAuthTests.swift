import XCTest
@testable import SentinelSDK

final class MobfacilAuthTests: XCTestCase {

    private let sampleAccessToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.sample_token_payload"
    private let sampleNewAccessToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.renewed_token_payload"

    // MARK: - Flow 1: Company Authentication Tests

    func testFlow1_CompanyAuthenticationSuccessAndPersistence() async throws {
        let mockTransport = MockMobfacilHTTPTransport()
        let config = MobfacilAuthConfig()
        let storage = InMemoryMobfacilTokenStorage()

        // Setup mock response for /login/token
        mockTransport.registerHandler(forPath: "/login/token") { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")

            let bodyString = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
            XCTAssertTrue(bodyString.contains("grant_type=client_credentials"))
            XCTAssertTrue(bodyString.contains("client_id=sdk_ken_QA"))
            XCTAssertTrue(bodyString.contains("client_secret=nkO2atoPD3po2U3vPYQz8m8V1LXq84fU"))

            let jsonResponse = """
            {
                "access_token": "\(self.sampleAccessToken)",
                "expires_in": 300,
                "token_type": "Bearer",
                "refresh_expires_in": 0
            }
            """
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (jsonResponse.data(using: .utf8)!, response)
        }

        let tokenManager = MobfacilTokenManager(config: config, storage: storage, transport: mockTransport)

        // Request token
        let token = try await tokenManager.getValidToken()

        XCTAssertEqual(token.accessToken, sampleAccessToken)
        XCTAssertEqual(token.expiresIn, 300)
        XCTAssertEqual(token.tokenType, "Bearer")
        XCTAssertFalse(token.isExpired)
        XCTAssertFalse(token.isExpiringSoon)
        XCTAssertGreaterThan(token.remainingSeconds, 290)

        // Verify token was persisted to storage
        let persisted = await storage.loadToken()
        XCTAssertNotNil(persisted)
        XCTAssertEqual(persisted?.accessToken, sampleAccessToken)

        // Verify app restart reuse: A second token manager with same storage does not call IDP again
        mockTransport.resetExecutedRequests()
        let newManagerAfterRestart = MobfacilTokenManager(config: config, storage: storage, transport: mockTransport)
        let reusedToken = try await newManagerAfterRestart.getValidToken()
        XCTAssertEqual(reusedToken.accessToken, sampleAccessToken)
        XCTAssertEqual(mockTransport.executedRequests.count, 0, "Token should be reused from persistent storage without network call")
    }

    // MARK: - Flow 2: Data Transmission with Bearer Token

    func testFlow2_DataTransmissionWithBearerToken() async throws {
        let mockTransport = MockMobfacilHTTPTransport()
        let config = MobfacilAuthConfig()
        let initialToken = MobfacilToken(
            accessToken: sampleAccessToken,
            expiresIn: 300,
            tokenType: "Bearer"
        )
        let storage = InMemoryMobfacilTokenStorage(initialToken: initialToken)
        let tokenManager = MobfacilTokenManager(config: config, storage: storage, transport: mockTransport)

        var capturedAuthHeader: String?
        var capturedBody: String?

        mockTransport.registerHandler(forPath: "/telemetry") { request in
            capturedAuthHeader = request.value(forHTTPHeaderField: "Authorization")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
            if let bodyData = request.httpBody {
                capturedBody = String(data: bodyData, encoding: .utf8)
            }

            let responseBody = """
            {
                "status_code": 200,
                "tracking_id": "trk_abc12345",
                "message": "Telemetry received successfully"
            }
            """
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (responseBody.data(using: .utf8)!, response)
        }

        let collector = MobfacilCollectorService(config: config, tokenManager: tokenManager, transport: mockTransport)

        // Transmit sample JSON
        let payloadJSON = "{\"device_id\":\"iphone15\",\"os\":\"ios17\"}"
        let collectorResponse = try await collector.transmit(jsonString: payloadJSON)

        XCTAssertTrue(collectorResponse.success)
        XCTAssertEqual(collectorResponse.statusCode, 200)
        XCTAssertEqual(collectorResponse.trackingId, "trk_abc12345")
        XCTAssertEqual(capturedAuthHeader, "Bearer \(sampleAccessToken)")
        XCTAssertEqual(capturedBody, payloadJSON)
    }

    // MARK: - Flow 2 Alt: 401 Retry on Token Expired in Flight

    func testFlow2Alt_401RetryFlow() async throws {
        let mockTransport = MockMobfacilHTTPTransport()
        let config = MobfacilAuthConfig()

        // Expired token in cache
        let expiredToken = MobfacilToken(
            accessToken: "expired_token_in_flight",
            expiresIn: 300,
            tokenType: "Bearer",
            createdAt: Date().addingTimeInterval(-350), // Issued 350s ago
            expiresAt: Date().addingTimeInterval(50)    // App thought it had 50s left, but server rejected
        )
        let storage = InMemoryMobfacilTokenStorage(initialToken: expiredToken)
        let tokenManager = MobfacilTokenManager(config: config, storage: storage, transport: mockTransport)

        var telemetryAttemptCount = 0

        // Mock IDP /login/token endpoint
        mockTransport.registerHandler(forPath: "/login/token") { request in
            let jsonResponse = """
            {
                "access_token": "\(self.sampleNewAccessToken)",
                "expires_in": 300,
                "token_type": "Bearer",
                "refresh_expires_in": 0
            }
            """
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (jsonResponse.data(using: .utf8)!, response)
        }

        // Mock /telemetry endpoint: Fails with 401 on 1st attempt, succeeds with 200 on 2nd attempt
        mockTransport.registerHandler(forPath: "/telemetry") { request in
            telemetryAttemptCount += 1
            let authHeader = request.value(forHTTPHeaderField: "Authorization")

            if telemetryAttemptCount == 1 {
                XCTAssertEqual(authHeader, "Bearer expired_token_in_flight")
                let errorBody = "{\"error\": \"unauthorized\", \"message\": \"Token has expired\"}"
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 401,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (errorBody.data(using: .utf8)!, response)
            } else {
                XCTAssertEqual(authHeader, "Bearer \(self.sampleNewAccessToken)")
                let successBody = "{\"status_code\": 200, \"tracking_id\": \"retry_success_123\"}"
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                )!
                return (successBody.data(using: .utf8)!, response)
            }
        }

        let collector = MobfacilCollectorService(config: config, tokenManager: tokenManager, transport: mockTransport)
        let response = try await collector.transmit(jsonString: "{\"data\":\"test_payload\"}")

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.trackingId, "retry_success_123")
        XCTAssertEqual(telemetryAttemptCount, 2, "Should have retried telemetry transmission once")

        // Token manager should now hold the refreshed token
        let currentToken = await tokenManager.getValidToken()
        XCTAssertEqual(currentToken.accessToken, sampleNewAccessToken)
    }

    // MARK: - Flow 3: Proactive Renewal & Concurrency Safety

    func testFlow3_ExpirationMathAndProactiveRenewal() {
        let now = Date()

        // Token with 120s remaining (healthy)
        let healthyToken = MobfacilToken(
            accessToken: "healthy",
            expiresIn: 300,
            tokenType: "Bearer",
            createdAt: now.addingTimeInterval(-180),
            expiresAt: now.addingTimeInterval(120)
        )
        XCTAssertFalse(healthyToken.isExpired(at: now))
        XCTAssertFalse(healthyToken.isExpiringSoon(bufferSeconds: 60, at: now))
        XCTAssertEqual(Int(healthyToken.remainingSeconds(from: now)), 120)

        // Token with 45s remaining (<= 60s -> expiring soon)
        let expiringSoonToken = MobfacilToken(
            accessToken: "expiring_soon",
            expiresIn: 300,
            tokenType: "Bearer",
            createdAt: now.addingTimeInterval(-255),
            expiresAt: now.addingTimeInterval(45)
        )
        XCTAssertFalse(expiringSoonToken.isExpired(at: now))
        XCTAssertTrue(expiringSoonToken.isExpiringSoon(bufferSeconds: 60, at: now))
        XCTAssertEqual(Int(expiringSoonToken.remainingSeconds(from: now)), 45)

        // Token with 0s remaining (expired)
        let expiredToken = MobfacilToken(
            accessToken: "expired",
            expiresIn: 300,
            tokenType: "Bearer",
            createdAt: now.addingTimeInterval(-300),
            expiresAt: now
        )
        XCTAssertTrue(expiredToken.isExpired(at: now))
        XCTAssertTrue(expiredToken.isExpiringSoon(bufferSeconds: 60, at: now))
        XCTAssertLessThanOrEqual(expiredToken.remainingSeconds(from: now), 0)
    }

    func testFlow3_ConcurrencySafetySingleInFlightRenewal() async throws {
        let mockTransport = MockMobfacilHTTPTransport()
        let config = MobfacilAuthConfig()
        let storage = InMemoryMobfacilTokenStorage()

        var tokenRequestCounter = 0
        let counterLock = NSLock()

        mockTransport.registerHandler(forPath: "/login/token") { request in
            counterLock.lock()
            tokenRequestCounter += 1
            counterLock.unlock()

            // Simulate network latency of 50ms
            Thread.sleep(forTimeInterval: 0.05)

            let jsonResponse = """
            {
                "access_token": "coalesced_token_\(UUID().uuidString)",
                "expires_in": 300,
                "token_type": "Bearer",
                "refresh_expires_in": 0
            }
            """
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (jsonResponse.data(using: .utf8)!, response)
        }

        let tokenManager = MobfacilTokenManager(config: config, storage: storage, transport: mockTransport)

        // Launch 15 concurrent callers simultaneously requesting a token
        let concurrentCallers = 15
        let tokens = try await withThrowingTaskGroup(of: MobfacilToken.self) { group -> [MobfacilToken] in
            for _ in 0..<concurrentCallers {
                group.addTask {
                    return try await tokenManager.getValidToken(forceRefresh: true)
                }
            }

            var results: [MobfacilToken] = []
            for try await token in group {
                results.append(token)
            }
            return results
        }

        XCTAssertEqual(tokens.count, concurrentCallers)
        // All callers must receive the exact same renewed token
        let firstToken = tokens.first?.accessToken
        XCTAssertNotNil(firstToken)
        for token in tokens {
            XCTAssertEqual(token.accessToken, firstToken, "Concurrent callers must share the exact same coalesced in-flight token")
        }

        // Concurrency lock assertion: Exactly 1 HTTP request must have been made to /login/token
        counterLock.lock()
        let finalCount = tokenRequestCounter
        counterLock.unlock()
        XCTAssertEqual(finalCount, 1, "Only 1 in-flight renewal request must be fired across all concurrent callers")
    }

    // MARK: - Flow 4: Inadimplência / Suspended License (invalid_client)

    func testFlow4_InadimplenciaSuspendedLicenseMapping() async {
        let mockTransport = MockMobfacilHTTPTransport()
        let config = MobfacilAuthConfig()
        let storage = InMemoryMobfacilTokenStorage()

        // Keycloak returns 400 or 401 with invalid_client
        mockTransport.registerHandler(forPath: "/login/token") { request in
            let errorJson = """
            {
                "error": "invalid_client",
                "error_description": "Invalid client or Invalid client credentials"
            }
            """
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 400,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (errorJson.data(using: .utf8)!, response)
        }

        let tokenManager = MobfacilTokenManager(config: config, storage: storage, transport: mockTransport)

        do {
            _ = try await tokenManager.getValidToken()
            XCTFail("Should have thrown MobfacilAuthError.licenseBlocked")
        } catch let error as MobfacilAuthError {
            guard case .licenseBlocked(let description) = error else {
                XCTFail("Expected MobfacilAuthError.licenseBlocked, got \(error)")
                return
            }
            XCTAssertTrue(error.isLicenseBlocked)
            XCTAssertFalse(error.isUnauthorizedClient)
            XCTAssertTrue(description.contains("Invalid client"))
            XCTAssertTrue(error.localizedDescription.contains("Licença bloqueada por inadimplência"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Flow 5: Secret Rotated or Compromised (unauthorized_client)

    func testFlow5_SecretRotatedOrCompromisedMapping() async {
        let mockTransport = MockMobfacilHTTPTransport()
        let config = MobfacilAuthConfig()
        let storage = InMemoryMobfacilTokenStorage()

        // Keycloak returns 401 with unauthorized_client
        mockTransport.registerHandler(forPath: "/login/token") { request in
            let errorJson = """
            {
                "error": "unauthorized_client",
                "error_description": "Invalid client or Invalid client credentials"
            }
            """
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (errorJson.data(using: .utf8)!, response)
        }

        let tokenManager = MobfacilTokenManager(config: config, storage: storage, transport: mockTransport)

        do {
            _ = try await tokenManager.getValidToken()
            XCTFail("Should have thrown MobfacilAuthError.unauthorizedClient")
        } catch let error as MobfacilAuthError {
            guard case .unauthorizedClient(let description) = error else {
                XCTFail("Expected MobfacilAuthError.unauthorizedClient, got \(error)")
                return
            }
            XCTAssertTrue(error.isUnauthorizedClient)
            XCTAssertFalse(error.isLicenseBlocked)
            XCTAssertTrue(description.contains("Invalid client"))
            XCTAssertTrue(error.localizedDescription.contains("Credenciais inválidas ou secret rotacionado"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Resilient Networking & International DNS Fallback

    func testDNSFallbackResolver_WhenSystemDNSFails_FallsBackToConfiguredIP() async throws {
        // Simulate system DNS lookup throwing a cannot find host error
        let resolver = DefaultMobfacilDNSResolver(
            fallbackMapping: ["api.stg.mobfacil.com.br": "65.21.200.181"],
            systemResolver: { host in
                throw NSError(domain: NSURLErrorDomain, code: -1003, userInfo: [NSLocalizedDescriptionKey: "UnknownHostException / Cannot find host"])
            }
        )

        let resolvedIPs = try await resolver.resolve(host: "api.stg.mobfacil.com.br")
        XCTAssertEqual(resolvedIPs, ["65.21.200.181"])
    }

    func testDNSFallback_URLPreservesHostnameAndSNI() async throws {
        let config = MobfacilAuthConfig(
            dnsFallbackHost: "api.stg.mobfacil.com.br",
            dnsFallbackIP: "65.21.200.181",
            dnsFallbackEnabled: true
        )

        // URL must strictly remain https://api.stg.mobfacil.com.br/login/token (never the raw IP)
        XCTAssertEqual(config.fullTokenURL.absoluteString, "https://api.stg.mobfacil.com.br/login/token")
        XCTAssertEqual(config.fullDataURL.absoluteString, "https://api.stg.mobfacil.com.br/telemetry")
        XCTAssertFalse(config.fullTokenURL.absoluteString.contains("65.21.200.181"))
        XCTAssertEqual(config.fullTokenURL.host, "api.stg.mobfacil.com.br")
    }

    func testDefaultHTTPTransport_WhenDNSFails_InvokesSocketFallbackWithSNI() async throws {
        let config = MobfacilAuthConfig(
            dnsFallbackHost: "api.stg.mobfacil.com.br",
            dnsFallbackIP: "65.21.200.181",
            dnsFallbackEnabled: true
        )

        let sessionConfig = URLSessionConfiguration.ephemeral
        sessionConfig.protocolClasses = [FailingHostURLProtocol.self]
        let session = URLSession(configuration: sessionConfig)

        let mockSocket = MockSocketTransport()
        let transport = DefaultMobfacilHTTPTransport(
            config: config,
            session: session,
            socketTransport: mockSocket
        )

        var request = URLRequest(url: config.fullTokenURL)
        request.httpMethod = "POST"

        let (data, response) = try await transport.execute(request: request)

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(mockSocket.recordedFallbackIP, "65.21.200.181")
        XCTAssertEqual(mockSocket.recordedSNIHost, "api.stg.mobfacil.com.br")
        XCTAssertEqual(mockSocket.recordedURL?.absoluteString, "https://api.stg.mobfacil.com.br/login/token")
        XCTAssertEqual(String(data: data, encoding: .utf8), "{\"status\": \"fallback_ok\"}")
    }

    // MARK: - SentinelSDK Facade Integration Test

    func testSentinelSDK_FacadeTransmissionIntegration() async throws {
        let mockTransport = MockMobfacilHTTPTransport()
        let config = MobfacilAuthConfig()
        let initialToken = MobfacilToken(accessToken: "facade_token", expiresIn: 300)
        let storage = InMemoryMobfacilTokenStorage(initialToken: initialToken)

        mockTransport.registerHandler(forPath: "/telemetry") { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer facade_token")
            let responseBody = "{\"status_code\": 200, \"tracking_id\": \"facade_success_999\"}"
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (responseBody.data(using: .utf8)!, response)
        }

        let sdk = SentinelSDK.shared
        sdk.configureMobfacil(config: config, storage: storage, transport: mockTransport)

        let captureConfig = SentinelSDK.CaptureConfiguration(
            userData: PersonalDataValidator.Input(
                fullName: "Carlos Eduardo da Silva",
                documentId: "123.456.789-09",
                email: "carlos.silva@example.com",
                phoneNumber: "+5511999998888"
            ),
            locationTimeoutSeconds: 1.0,
            wrapper: "native_ios_test"
        )

        let result = try await sdk.transmitTelemetry(configuration: captureConfig)
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.statusCode, 200)
        XCTAssertEqual(result.trackingId, "facade_success_999")
    }
}

// MARK: - Test Doubles for Network & DNS Fallback Verification

private final class MockSocketTransport: MobfacilSocketTransportProtocol, @unchecked Sendable {
    var recordedFallbackIP: String?
    var recordedSNIHost: String?
    var recordedURL: URL?

    func executeWithFallback(
        request: URLRequest,
        fallbackIP: String,
        sniHost: String
    ) async throws -> (Data, HTTPURLResponse) {
        self.recordedFallbackIP = fallbackIP
        self.recordedSNIHost = sniHost
        self.recordedURL = request.url

        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        let data = "{\"status\": \"fallback_ok\"}".data(using: .utf8)!
        return (data, response)
    }
}

private final class FailingHostURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        let error = URLError(.cannotFindHost)
        client?.urlProtocol(self, didFailWithError: error)
    }

    override func stopLoading() {}
}
