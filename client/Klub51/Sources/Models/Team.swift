import Foundation

struct Team: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let createdAt: String
    let updatedAt: String
    let memberships: [TeamMembership]?
    let memberCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, memberships
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case memberCount = "member_count"
    }
}

struct TeamMembership: Codable, Identifiable, Sendable {
    let id: Int
    let user: User
    let role: MemberRole
    let joinedAt: String

    enum CodingKeys: String, CodingKey {
        case id, user, role
        case joinedAt = "joined_at"
    }
}

enum MemberRole: String, Codable, Sendable {
    case owner
    case editor
    case viewer

    var displayName: String {
        switch self {
        case .owner: "Владелец"
        case .editor: "Редактор"
        case .viewer: "Читатель"
        }
    }
}
