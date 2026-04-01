import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIEndpoint {
    // Auth
    case login(username: String, password: String)
    case refreshToken(refresh: String)
    case me

    // Teams
    case teams
    case teamMembers(teamId: Int)

    // Projects
    case projects
    case projectDetail(id: Int)
    case createProject
    case updateProject(id: Int)
    case deleteProject(id: Int)

    // Technical Card
    case technicalCard(projectId: Int)
    case updateTechnicalCard(projectId: Int)

    // Statuses
    case statuses

    // Pages
    case pages
    case pageDetail(id: Int)
    case createPage
    case updatePage(id: Int)
    case deletePage(id: Int)

    // Blocks
    case blocks
    case updateBlock(id: Int)
    case deleteBlock(id: Int)
    case reorderBlocks(pageId: Int)

    var path: String {
        switch self {
        case .login: "/api/auth/login/"
        case .refreshToken: "/api/auth/refresh/"
        case .me: "/api/auth/me/"

        case .teams: "/api/auth/teams/"
        case .teamMembers(let id): "/api/auth/teams/\(id)/members/"

        case .projects, .createProject: "/api/projects/"
        case .projectDetail(let id), .updateProject(let id), .deleteProject(let id):
            "/api/projects/\(id)/"

        case .technicalCard(let id), .updateTechnicalCard(let id):
            "/api/projects/\(id)/card/"

        case .statuses: "/api/statuses/"

        case .pages, .createPage: "/api/pages/"
        case .pageDetail(let id), .updatePage(let id), .deletePage(let id):
            "/api/pages/\(id)/"

        case .blocks: "/api/blocks/"
        case .updateBlock(let id), .deleteBlock(let id):
            "/api/blocks/\(id)/"
        case .reorderBlocks(let id):
            "/api/pages/\(id)/reorder_blocks/"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .refreshToken, .createProject, .createPage, .reorderBlocks:
            .post
        case .updateProject, .updateTechnicalCard, .updatePage, .updateBlock:
            .patch
        case .deleteProject, .deletePage, .deleteBlock:
            .delete
        default:
            .get
        }
    }
}
