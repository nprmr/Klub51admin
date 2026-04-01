import Foundation

struct Page: Codable, Identifiable, Sendable {
    let id: Int
    var title: String
    var icon: String
    var parent: Int?
    var order: Int
    var childrenCount: Int?
    var blocks: [PageBlock]?
    var children: [Page]?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, title, icon, parent, order, blocks, children
        case childrenCount = "children_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct PageCreateRequest: Codable, Sendable {
    let project: Int
    var title: String
    var icon: String = ""
    var parent: Int?
    var order: Int = 0
}
