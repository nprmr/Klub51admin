import Foundation

struct AuthTokenResponse: Codable, Sendable {
    let access: String
    let refresh: String
    let isNew: Bool
    let authProvider: String
    let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case access, refresh, user
        case isNew = "is_new"
        case authProvider = "auth_provider"
    }
}

struct AuthUser: Codable, Sendable {
    let id: Int
    let username: String
    let email: String
    let firstName: String
    let lastName: String
    let hasPassword: Bool

    enum CodingKeys: String, CodingKey {
        case id, username, email
        case firstName = "first_name"
        case lastName = "last_name"
        case hasPassword = "has_password"
    }

    func toUser() -> User {
        User(id: id, username: username, email: email, firstName: firstName, lastName: lastName)
    }
}

struct OTPRequestResponse: Codable, Sendable {
    let detail: String
}

struct AuthProvidersResponse: Codable, Sendable {
    let providers: [String: Bool]
    let clientIds: [String: String]

    enum CodingKeys: String, CodingKey {
        case providers
        case clientIds = "client_ids"
    }
}

struct CompleteProfileRequest: Encodable, Sendable {
    let firstName: String
    let lastName: String
    let password: String?

    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case password
    }
}

struct CompleteProfileResponse: Codable, Sendable {
    let user: AuthUser
}
