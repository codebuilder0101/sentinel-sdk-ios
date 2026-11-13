import Foundation

/// Thread-safe actor managing OAuth2 client credentials authentication, caching,
/// proactive renewal, error mapping, and token persistence for MobFácil.
public actor MobfacilTokenManager {
    public let config: MobfacilAuthConfig
    private let storage: MobfacilTokenStorage
    private let transport: MobfacilHTTPTransport

    private var cachedToken: MobfacilToken?
    private var activeRenewalTask: Task<MobfacilToken, Error>?

    public init(
        config: MobfacilAuthConfig = MobfacilAuthConfig(),
        storage: MobfacilTokenStorage? = nil,
        transport: MobfacilHTTPTransport? = nil
    ) {
        self.config = config
        self.storage = storage ?? UserDefaultsMobfacilTokenStorage()
        self.transport = transport ?? DefaultMobfacilHTTPTransport(config: config)
    }

    /// Retrieves an unexpired access token.
    /// - Parameter forceRefresh: When true, forces a new token request regardless of cache.
    /// - Returns: A valid MobfacilToken.
    public func getValidToken(forceRefresh: Bool = false) async throws -> MobfacilToken {
        if !forceRefresh {
            // Check memory cache or persistent storage
            if let token = await currentOrPersistedToken() {
                if !token.isExpired() {
                    // Check proactive background renewal threshold (remainingSeconds <= 60s)
                    if token.isExpiringSoon(bufferSeconds: config.renewalBufferSeconds) {
                        triggerProactiveBackgroundRenewal()
                    }
                    return token
                }
            }
        }

        // Token is missing, expired, or forced refresh is requested.
        return try await executeOrCoalesceRenewal()
    }

    /// Triggers background token renewal if no renewal is currently in-flight.
    public func triggerProactiveBackgroundRenewal() {
        guard activeRenewalTask == nil else { return }

        activeRenewalTask = Task<MobfacilToken, Error> { [weak self] in
            guard let self = self else {
                throw MobfacilAuthError.cancelled
            }
            return try await self.executeRenewal()
        }
    }

    /// Direct authentication request via OAuth2 client_credentials grant.
    public func authenticate() async throws -> MobfacilToken {
        return try await executeOrCoalesceRenewal()
    }

    /// Invalidates the cached token in memory and in persistent storage.
    public func invalidateToken() async throws {
        cachedToken = nil
        try await storage.clearToken()
    }

    /// Inspects the current in-memory cached token.
    public func getCachedToken() -> MobfacilToken? {
        return cachedToken
    }

    // MARK: - Private Helpers

    private func currentOrPersistedToken() async -> MobfacilToken? {
        if let memory = cachedToken {
            return memory
        }
        if let stored = await storage.loadToken() {
            cachedToken = stored
            return stored
        }
        return nil
    }

    /// Concurrency-safe execution: Coalesces concurrent callers into a single in-flight Task.
    private func executeOrCoalesceRenewal() async throws -> MobfacilToken {
        if let inFlight = activeRenewalTask {
            return try await inFlight.value
        }

        let task = Task<MobfacilToken, Error> { [weak self] in
            guard let self = self else {
                throw MobfacilAuthError.cancelled
            }
            return try await self.executeRenewal()
        }

        activeRenewalTask = task
        return try await task.value
    }

    private func executeRenewal() async throws -> MobfacilToken {
        defer {
            activeRenewalTask = nil
        }

        let token = try await requestTokenFromIDP()
        cachedToken = token
        try? await storage.saveToken(token)
        return token
    }

    private func requestTokenFromIDP() async throws -> MobfacilToken {
        var request = URLRequest(url: config.fullTokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = config.requestTimeout

        // Build form url-encoded body: grant_type, client_id, client_secret
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: config.grantType),
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "client_secret", value: config.clientSecret)
        ]

        guard let bodyString = components.percentEncodedQuery,
              let bodyData = bodyString.data(using: .utf8) else {
            throw MobfacilAuthError.decodingError("Failed to encode form parameters")
        }
        request.httpBody = bodyData

        let (data, response) = try await transport.execute(request: request)
        let statusCode = response.statusCode

        // Flow 1: 200 OK
        if (200...299).contains(statusCode) {
            do {
                let decoder = JSONDecoder()
                let token = try decoder.decode(MobfacilToken.self, from: data)
                return token
            } catch {
                throw MobfacilAuthError.decodingError("Failed to parse token response: \(error)")
            }
        }

        // Map Keycloak OAuth2 errors
        let bodyStringFallback = String(data: data, encoding: .utf8)
        if let oauthError = try? JSONDecoder().decode(MobfacilOAuthErrorResponse.self, from: data) {
            let errorType = oauthError.error.lowercased()
            let description = oauthError.errorDescription ?? bodyStringFallback ?? "No description"

            // Flow 4: Inadimplência / Suspended License
            if errorType == "invalid_client" {
                throw MobfacilAuthError.licenseBlocked(description: description)
            }

            // Flow 5: Secret Rotated or Compromised
            if errorType == "unauthorized_client" {
                throw MobfacilAuthError.unauthorizedClient(description: description)
            }
        }

        throw MobfacilAuthError.httpError(statusCode: statusCode, body: bodyStringFallback)
    }
}

