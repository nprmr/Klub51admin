import Foundation

struct PageBlock: Codable, Identifiable, Sendable {
    let id: Int
    var blockType: BlockType
    var content: BlockContent
    var order: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, content, order
        case blockType = "block_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum BlockType: String, Codable, Sendable, CaseIterable {
    case text
    case heading1
    case heading2
    case heading3
    case bulletList = "bullet_list"
    case numberedList = "numbered_list"
    case todo
    case table
    case code
    case quote
    case divider
    case image

    var displayName: String {
        switch self {
        case .text: "Текст"
        case .heading1: "Заголовок 1"
        case .heading2: "Заголовок 2"
        case .heading3: "Заголовок 3"
        case .bulletList: "Список"
        case .numberedList: "Нумерованный список"
        case .todo: "Чек-лист"
        case .table: "Таблица"
        case .code: "Код"
        case .quote: "Цитата"
        case .divider: "Разделитель"
        case .image: "Изображение"
        }
    }

    var systemImage: String {
        switch self {
        case .text: "text.alignleft"
        case .heading1: "textformat.size.larger"
        case .heading2: "textformat.size"
        case .heading3: "textformat.size.smaller"
        case .bulletList: "list.bullet"
        case .numberedList: "list.number"
        case .todo: "checklist"
        case .table: "tablecells"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .quote: "text.quote"
        case .divider: "minus"
        case .image: "photo"
        }
    }
}

struct BlockContent: Codable, Sendable {
    var text: String?
    var checked: Bool?
    var rows: [[String]]?
    var language: String?
    var url: String?

    init(text: String? = nil, checked: Bool? = nil, rows: [[String]]? = nil, language: String? = nil, url: String? = nil) {
        self.text = text
        self.checked = checked
        self.rows = rows
        self.language = language
        self.url = url
    }
}

// MARK: - API Responses

struct PaginatedResponse<T: Codable & Sendable>: Codable, Sendable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [T]
}

struct AuthTokenResponse: Codable, Sendable {
    let access: String
    let refresh: String
}
