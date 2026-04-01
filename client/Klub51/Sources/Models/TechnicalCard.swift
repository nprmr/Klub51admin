import Foundation

struct TechnicalCard: Codable, Identifiable, Sendable {
    let id: Int
    var githubUrl: String
    var appstoreUrl: String
    var figmaUrl: String
    var domainName: String
    var domainRegistrar: String
    var domainExpires: String?
    var budgetRequired: String?
    var budgetCurrency: String
    var adCabinetUrl: String
    var notes: String
    var customFields: [CustomField]?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id, notes
        case githubUrl = "github_url"
        case appstoreUrl = "appstore_url"
        case figmaUrl = "figma_url"
        case domainName = "domain_name"
        case domainRegistrar = "domain_registrar"
        case domainExpires = "domain_expires"
        case budgetRequired = "budget_required"
        case budgetCurrency = "budget_currency"
        case adCabinetUrl = "ad_cabinet_url"
        case customFields = "custom_fields"
        case updatedAt = "updated_at"
    }
}

struct TechnicalCardUpdate: Codable, Sendable {
    var githubUrl: String?
    var appstoreUrl: String?
    var figmaUrl: String?
    var domainName: String?
    var domainRegistrar: String?
    var domainExpires: String?
    var budgetRequired: String?
    var budgetCurrency: String?
    var adCabinetUrl: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case notes
        case githubUrl = "github_url"
        case appstoreUrl = "appstore_url"
        case figmaUrl = "figma_url"
        case domainName = "domain_name"
        case domainRegistrar = "domain_registrar"
        case domainExpires = "domain_expires"
        case budgetRequired = "budget_required"
        case budgetCurrency = "budget_currency"
        case adCabinetUrl = "ad_cabinet_url"
    }
}

struct CustomField: Codable, Identifiable, Sendable {
    let id: Int
    var label: String
    var value: String
    var fieldType: String
    var order: Int

    enum CodingKeys: String, CodingKey {
        case id, label, value, order
        case fieldType = "field_type"
    }
}
