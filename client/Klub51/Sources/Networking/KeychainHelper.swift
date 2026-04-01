import Foundation
import KeychainAccess

@MainActor
final class KeychainHelper: Sendable {
    static let shared = KeychainHelper()

    private let keychain = Keychain(service: "com.klub51.admin")
    private let accessTokenKey = "access_token"
    private let refreshTokenKey = "refresh_token"
    private let serverURLKey = "server_url"

    var accessToken: String? {
        get { keychain[accessTokenKey] }
        set { keychain[accessTokenKey] = newValue }
    }

    var refreshToken: String? {
        get { keychain[refreshTokenKey] }
        set { keychain[refreshTokenKey] = newValue }
    }

    var serverURL: String {
        get { keychain[serverURLKey] ?? "http://localhost:8000" }
        set { keychain[serverURLKey] = newValue }
    }

    func saveTokens(access: String, refresh: String) {
        accessToken = access
        refreshToken = refresh
    }

    func clearTokens() {
        accessToken = nil
        refreshToken = nil
    }

    var isAuthenticated: Bool {
        accessToken != nil
    }
}
