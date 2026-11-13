import Foundation

/// Represents a MobFácil Keycloak OAuth2 token response and runtime state.
public struct MobfacilToken: Codable, Sendable, Equatable {
    /// JWT Bearer access token string.
    public let accessToken: String

    /// Expiration lifetime in seconds from issue time (typically 300s).
    public let expiresIn: Int

    /// Token type (typically "Bearer").
    public let tokenType: String

    /// Refresh token expiration in seconds (typically 0 for client_credentials).
    public let refreshExpiresIn: Int?

    /// Local timestamp when the token was issued/received.
    public let createdAt: Date

    /// Calculated absolute expiration timestamp (createdAt + expiresIn).
    public let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case refreshExpiresIn = "refresh_expires_in"
        case createdAt = "created_at"
        case expiresAt = "expires_at"
    }

    public init(
        accessToken: String,
        expiresIn: Int,
        tokenType: String = "Bearer",
        refreshExpiresIn: Int? = 0,
        createdAt: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
        self.refreshExpiresIn = refreshExpiresIn
        self.createdAt = createdAt
        self.expiresAt = expiresAt ?? createdAt.addingTimeInterval(TimeInterval(expiresIn))
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.expiresIn = try container.decode(Int.self, forKey: .expiresIn)
        self.tokenType = try container.decodeIfPresent(String.self, forKey: .tokenType) ?? "Bearer"
        self.refreshExpiresIn = try container.decodeIfPresent(Int.self, forKey: .refreshExpiresIn)

        if let persistedCreatedAt = try container.decodeIfPresent(Date.self, forKey: .createdAt),
           let persistedExpiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt) {
            self.createdAt = persistedCreatedAt
            self.expiresAt = persistedExpiresAt
        } else {
            let now = Date()
            self.createdAt = now
            self.expiresAt = now.addingTimeInterval(TimeInterval(self.expiresIn))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(expiresIn, forKey: .expiresIn)
        try container.encode(tokenType, forKey: .tokenType)
        try container.encodeIfPresent(refreshExpiresIn, forKey: .refreshExpiresIn)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(expiresAt, forKey: .expiresAt)
    }

    /// Remaining lifetime in seconds from the reference date (defaults to now).
    public func remainingSeconds(from date: Date = Date()) -> TimeInterval {
        return expiresAt.timeIntervalSince(date)
    }

    /// Returns true if the token is completely expired.
    public func isExpired(at date: Date = Date()) -> Bool {
        return remainingSeconds(from: date) <= 0
    }

    /// Returns true if the token expires within the buffer seconds (default: 60s).
    public func isExpiringSoon(bufferSeconds: TimeInterval = 60.0, at date: Date = Date()) -> Bool {
        return remainingSeconds(from: date) <= bufferSeconds
    }

    /// Quick boolean property for whether the token has expired as of now.
    public var isExpired: Bool {
        return isExpired()
    }

    /// Quick boolean property for whether the token expires within 60s of now.
    public var isExpiringSoon: Bool {
        return isExpiringSoon()
    }

    /// Quick property returning remaining seconds from now.
    public var remainingSeconds: TimeInterval {
        return remainingSeconds()
    }
}

/// Raw OAuth2 error response body from Keycloak / KrakenD.
public struct MobfacilOAuthErrorResponse: Codable, Sendable, Equatable {
    public let error: String
    public let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
    }

    public init(error: String, errorDescription: String? = nil) {
        self.error = error
        self.errorDescription = errorDescription
    }
}

/// Domain-specific errors mapped to business lifecycle conditions.
public enum MobfacilAuthError: LocalizedError, Sendable, Equatable {
    /// Flow 4: Inadimplência / Suspended License (mapped from invalid_client)
    case licenseBlocked(description: String)

    /// Flow 5: Secret Rotated or Compromised (mapped from unauthorized_client)
    case unauthorizedClient(description: String)

    /// Missing or uninitialized token
    case invalidToken

    /// Token has expired
    case tokenExpired

    /// HTTP error response with status code and body
    case httpError(statusCode: Int, body: String?)

    /// Network socket, connection, or transport error
    case networkError(String)

    /// JSON / Payload serialization or decoding error
    case decodingError(String)

    /// DNS failure where host could not be resolved
    case dnsResolutionFailed(host: String)

    /// Network operation was cancelled
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .licenseBlocked(let description):
            return "Licença bloqueada por inadimplência: \(description)"
        case .unauthorizedClient(let description):
            return "Credenciais inválidas ou secret rotacionado: \(description)"
        case .invalidToken:
            return "Token inválido ou ausente"
        case .tokenExpired:
            return "Token de autenticação expirado"
        case .httpError(let statusCode, let body):
            return "Erro HTTP \(statusCode): \(body ?? "sem conteúdo")"
        case .networkError(let message):
            return "Erro de rede: \(message)"
        case .decodingError(let message):
            return "Erro de decodificação: \(message)"
        case .dnsResolutionFailed(let host):
            return "Falha ao resolver DNS para \(host)"
        case .cancelled:
            return "Operação cancelada"
        }
    }

    public var isLicenseBlocked: Bool {
        if case .licenseBlocked = self { return true }
        return false
    }

    public var isUnauthorizedClient: Bool {
        if case .unauthorizedClient = self { return true }
        return false
    }
}

/// Telemetry transmission response from the collector gateway.
public struct MobfacilCollectorResponse: Codable, Sendable, Equatable {
    public let statusCode: Int
    public let success: Bool
    public let trackingId: String?
    public let message: String?
    public let timestamp: Date
    public let rawData: Data?

    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case success
        case trackingId = "tracking_id"
        case message
        case timestamp
    }

    public init(
        statusCode: Int,
        success: Bool,
        trackingId: String? = nil,
        message: String? = nil,
        timestamp: Date = Date(),
        rawData: Data? = nil
    ) {
        self.statusCode = statusCode
        self.success = success
        self.trackingId = trackingId
        self.message = message
        self.timestamp = timestamp
        self.rawData = rawData
    }
}

