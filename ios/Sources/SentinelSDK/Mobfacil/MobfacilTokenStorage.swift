import Foundation

/// Protocol defining token persistence across application launches.
public protocol MobfacilTokenStorage: Sendable {
    func loadToken() async -> MobfacilToken?
    func saveToken(_ token: MobfacilToken) async throws
    func clearToken() async throws
}

/// Persistent token storage backed by UserDefaults.
public final class UserDefaultsMobfacilTokenStorage: MobfacilTokenStorage {
    private let userDefaults: UserDefaults
    private let storageKey: String

    public init(
        userDefaults: UserDefaults = .standard,
        storageKey: String = "com.sentinel.mobfacil.token"
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
    }

    public func loadToken() async -> MobfacilToken? {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(MobfacilToken.self, from: data)
    }

    public func saveToken(_ token: MobfacilToken) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(token)
        userDefaults.set(data, forKey: storageKey)
    }

    public func clearToken() async throws {
        userDefaults.removeObject(forKey: storageKey)
    }
}

/// In-memory token storage actor for ephemeral sessions and isolated unit testing.
public actor InMemoryMobfacilTokenStorage: MobfacilTokenStorage {
    private var token: MobfacilToken?

    public init(initialToken: MobfacilToken? = nil) {
        self.token = initialToken
    }

    public func loadToken() async -> MobfacilToken? {
        return token
    }

    public func saveToken(_ token: MobfacilToken) async throws {
        self.token = token
    }

    public func clearToken() async throws {
        self.token = nil
    }
}

