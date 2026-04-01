import Foundation

@MainActor
@Observable
final class ProjectDetailViewModel {
    var project: Project?
    var card: TechnicalCard?
    var pages: [Page] = []
    var isLoading = false
    var errorMessage: String?

    private let api = APIClient.shared
    let projectId: Int

    init(projectId: Int) {
        self.projectId = projectId
    }

    func loadAll() async {
        isLoading = true
        errorMessage = nil
        do {
            async let projectResponse: Project = api.request(.projectDetail(id: projectId))
            async let cardResponse: TechnicalCard = api.request(.technicalCard(projectId: projectId))
            async let pagesResponse: PaginatedResponse<Page> = api.request(
                .pages,
                queryItems: [URLQueryItem(name: "project", value: "\(projectId)")]
            )
            let (p, c, pg) = try await (projectResponse, cardResponse, pagesResponse)
            project = p
            card = c
            pages = pg.results
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateProject(title: String, description: String, icon: String, statusId: Int?) async {
        struct UpdateBody: Encodable {
            let title: String
            let description: String
            let icon: String
            let status: Int?
        }
        do {
            let updated: Project = try await api.request(
                .updateProject(id: projectId),
                body: UpdateBody(title: title, description: description, icon: icon, status: statusId)
            )
            project = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateCard(_ update: TechnicalCardUpdate) async {
        do {
            let updated: TechnicalCard = try await api.request(
                .updateTechnicalCard(projectId: projectId),
                body: update
            )
            card = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createPage(title: String) async {
        let request = PageCreateRequest(project: projectId, title: title)
        do {
            let _: Page = try await api.request(.createPage, body: request)
            let response: PaginatedResponse<Page> = try await api.request(
                .pages,
                queryItems: [URLQueryItem(name: "project", value: "\(projectId)")]
            )
            pages = response.results
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deletePage(_ page: Page) async {
        do {
            try await api.requestVoid(.deletePage(id: page.id))
            pages.removeAll { $0.id == page.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
