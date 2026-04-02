import Foundation

struct AuthTokenResponse: Codable, Sendable {
    let access: String
    let refresh: String
    let user: User
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
