import Foundation

struct User: Codable, Identifiable, Sendable {
    let id: Int
    let username: String
    let email: String
    let firstName: String
    let lastName: String

    var displayName: String {
        let full = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        return full.isEmpty ? username : full
    }

    enum CodingKeys: String, CodingKey {
        case id, username, email
        case firstName = "first_name"
        case lastName = "last_name"
    }
}
