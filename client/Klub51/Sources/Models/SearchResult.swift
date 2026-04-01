import Foundation

struct SearchResponse: Codable, Sendable {
    let projects: [Project]
    let pages: [Page]
}

struct DomainAlert: Codable, Identifiable, Sendable {
    var id: String { "\(projectId)-\(domainName)" }
    let projectId: Int
    let projectTitle: String
    let domainName: String
    let domainRegistrar: String
    let domainExpires: String
    let daysLeft: Int
    let isExpired: Bool

    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case projectTitle = "project_title"
        case domainName = "domain_name"
        case domainRegistrar = "domain_registrar"
        case domainExpires = "domain_expires"
        case daysLeft = "days_left"
        case isExpired = "is_expired"
    }
}
