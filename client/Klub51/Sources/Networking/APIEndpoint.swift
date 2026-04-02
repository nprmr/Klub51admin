import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIEndpoint {
    // Auth — OTP
    case otpRequest
    case otpVerify
    case authProviders
    case refreshToken(refresh: String)
    case me

    // Auth — Social
    case socialGitHub
    case socialGoogle
    case socialApple

    // Auth — SSO
    case ssoConfig
    case ssoCallback

    // Auth — Profile
    case completeProfile

    // Auth — Connected accounts
    case connectedAccounts
    case disconnectAccount

    // Teams
    case teams
    case teamMembers(teamId: Int)

    // Projects
    case projects
    case projectDetail(id: Int)
    case createProject
    case updateProject(id: Int)
    case deleteProject(id: Int)
    case archiveProject(id: Int)
    case favoriteProject(id: Int)
    case duplicateProject(id: Int)

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
    case duplicatePage(id: Int)

    // Blocks
    case blocks
    case updateBlock(id: Int)
    case deleteBlock(id: Int)
    case reorderBlocks(pageId: Int)

    // Search
    case search
    case domainsExpiring

    // Attachments
    case attachments
    case attachmentDetail(id: Int)

    var path: String {
        switch self {
        // Auth
        case .otpRequest: "/api/auth/otp/request/"
        case .otpVerify: "/api/auth/otp/verify/"
        case .authProviders: "/api/auth/providers/"
        case .refreshToken: "/api/auth/refresh/"
        case .me: "/api/auth/me/"

        case .socialGitHub: "/api/auth/social/github/"
        case .socialGoogle: "/api/auth/social/google/"
        case .socialApple: "/api/auth/social/apple/"

        case .ssoConfig: "/api/auth/sso/config/"
        case .ssoCallback: "/api/auth/sso/callback/"

        case .completeProfile: "/api/auth/complete-profile/"
        case .connectedAccounts, .disconnectAccount: "/api/auth/connected-accounts/"

        // Teams
        case .teams: "/api/auth/teams/"
        case .teamMembers(let id): "/api/auth/teams/\(id)/members/"

        // Projects
        case .projects, .createProject: "/api/projects/"
        case .projectDetail(let id), .updateProject(let id), .deleteProject(let id):
            "/api/projects/\(id)/"
        case .archiveProject(let id): "/api/projects/\(id)/archive/"
        case .favoriteProject(let id): "/api/projects/\(id)/favorite/"
        case .duplicateProject(let id): "/api/projects/\(id)/duplicate/"

        case .technicalCard(let id), .updateTechnicalCard(let id):
            "/api/projects/\(id)/card/"

        case .statuses: "/api/statuses/"

        // Pages
        case .pages, .createPage: "/api/pages/"
        case .pageDetail(let id), .updatePage(let id), .deletePage(let id):
            "/api/pages/\(id)/"
        case .duplicatePage(let id): "/api/pages/\(id)/duplicate/"

        case .blocks: "/api/blocks/"
        case .updateBlock(let id), .deleteBlock(let id):
            "/api/blocks/\(id)/"
        case .reorderBlocks(let id):
            "/api/pages/\(id)/reorder_blocks/"

        case .search: "/api/search/"
        case .domainsExpiring: "/api/domains/expiring/"

        case .attachments: "/api/attachments/"
        case .attachmentDetail(let id): "/api/attachments/\(id)/"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .otpRequest, .otpVerify, .refreshToken, .socialGitHub, .socialGoogle,
             .socialApple, .ssoCallback, .createProject, .createPage, .reorderBlocks,
             .archiveProject, .favoriteProject, .duplicateProject, .duplicatePage,
             .attachments:
            .post
        case .updateProject, .updateTechnicalCard, .updatePage, .updateBlock, .completeProfile:
            .patch
        case .deleteProject, .deletePage, .deleteBlock, .attachmentDetail, .disconnectAccount:
            .delete
        default:
            .get
        }
    }
}
