import Foundation

/// Configuration settings for the MobFácil Keycloak OAuth2 & KrakenD Gateway pipeline.
public struct MobfacilAuthConfig: Sendable, Equatable, Codable {
    public static let defaultBaseURL = URL(string: "https://api.stg.mobfacil.com.br")!
    public static let defaultTokenEndpoint = "/login/token"
    public static let defaultDataEndpoint = "/telemetry"
    public static let defaultClientID = "sdk_ken_QA"
    public static let defaultClientSecret = "nkO2atoPD3po2U3vPYQz8m8V1LXq84fU"
    public static let defaultGrantType = "client_credentials"
    public static let defaultRenewalBuffer: TimeInterval = 60.0
    public static let defaultFallbackHost = "api.stg.mobfacil.com.br"
    public static let defaultFallbackIP = "65.21.200.181"

    /// Base URL for the MobFácil IDP and KrakenD Gateway.
    public var baseUrl: URL

    /// Path or full URL for the OAuth2 token endpoint (POST /login/token).
    public var tokenEndpoint: String

    /// Path or full URL for the telemetry/data transmission endpoint.
    public var dataEndpoint: String

    /// Client ID for OAuth2 client_credentials grant.
    public var clientId: String

    /// Client Secret for OAuth2 client_credentials grant.
    public var clientSecret: String

    /// OAuth2 grant type (default: client_credentials).
    public var grantType: String

    /// Time buffer in seconds before expiration to trigger proactive renewal (default: 60s).
    public var renewalBufferSeconds: TimeInterval

    /// Network request timeout in seconds.
    public var requestTimeout: TimeInterval

    /// Staging hostname subject to international DNS resolution issues.
    public var dnsFallbackHost: String

    /// Static fallback IPv4 address for international DNS failure (preserving SNI).
    public var dnsFallbackIP: String

    /// Whether international DNS fallback is enabled.
    public var dnsFallbackEnabled: Bool

    public init(
        baseUrl: URL = MobfacilAuthConfig.defaultBaseURL,
        tokenEndpoint: String = MobfacilAuthConfig.defaultTokenEndpoint,
        dataEndpoint: String = MobfacilAuthConfig.defaultDataEndpoint,
        clientId: String = MobfacilAuthConfig.defaultClientID,
        clientSecret: String = MobfacilAuthConfig.defaultClientSecret,
        grantType: String = MobfacilAuthConfig.defaultGrantType,
        renewalBufferSeconds: TimeInterval = MobfacilAuthConfig.defaultRenewalBuffer,
        requestTimeout: TimeInterval = 30.0,
        dnsFallbackHost: String = MobfacilAuthConfig.defaultFallbackHost,
        dnsFallbackIP: String = MobfacilAuthConfig.defaultFallbackIP,
        dnsFallbackEnabled: Bool = true
    ) {
        self.baseUrl = baseUrl
        self.tokenEndpoint = tokenEndpoint
        self.dataEndpoint = dataEndpoint
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.grantType = grantType
        self.renewalBufferSeconds = renewalBufferSeconds
        self.requestTimeout = requestTimeout
        self.dnsFallbackHost = dnsFallbackHost
        self.dnsFallbackIP = dnsFallbackIP
        self.dnsFallbackEnabled = dnsFallbackEnabled
    }

    /// Resolves the absolute URL for the token endpoint.
    public var fullTokenURL: URL {
        if tokenEndpoint.hasPrefix("http://") || tokenEndpoint.hasPrefix("https://"),
           let absolute = URL(string: tokenEndpoint) {
            return absolute
        }
        return URL(string: tokenEndpoint, relativeTo: baseUrl)?.absoluteURL ?? baseUrl.appendingPathComponent(tokenEndpoint)
    }

    /// Resolves the absolute URL for the data transmission endpoint.
    public var fullDataURL: URL {
        if dataEndpoint.hasPrefix("http://") || dataEndpoint.hasPrefix("https://"),
           let absolute = URL(string: dataEndpoint) {
            return absolute
        }
        return URL(string: dataEndpoint, relativeTo: baseUrl)?.absoluteURL ?? baseUrl.appendingPathComponent(dataEndpoint)
    }
}
