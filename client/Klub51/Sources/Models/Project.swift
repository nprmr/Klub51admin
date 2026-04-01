import Foundation

struct Project: Codable, Identifiable, Sendable {
    let id: Int
    var title: String
    var description: String
    var icon: String
    var status: Int?
    var statusName: String?
    var statusColor: String?
    let team: Int
    var pageCount: Int?
    var technicalCard: TechnicalCard?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, description, icon, status, team
        case statusName = "status_name"
        case statusColor = "status_color"
        case pageCount = "page_count"
        case technicalCard = "technical_card"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ProjectStatus: Codable, Identifiable, Sendable {
    let id: Int
    var name: String
    var color: String
    var order: Int
    let team: Int
}

struct ProjectCreateRequest: Codable, Sendable {
    let title: String
    var description: String = ""
    var icon: String = ""
    var status: Int?
    let team: Int
}
