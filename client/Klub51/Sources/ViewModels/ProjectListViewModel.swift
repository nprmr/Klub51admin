import Foundation

@MainActor
@Observable
final class ProjectListViewModel {
    var projects: [Project] = []
    var statuses: [ProjectStatus] = []
    var isLoading = false
    var errorMessage: String?
    var showArchived = false

    private let api = APIClient.shared

    /// Projects grouped by status, sorted by status order (excluding favorites from groups to avoid duplication)
    var groupedProjects: [(status: ProjectStatus, projects: [Project])] {
        let nonFavorite = projects.filter { $0.isFavorite != true }
        let statusMap = Dictionary(grouping: nonFavorite) { $0.status }
        return statuses.map { status in
            (status: status, projects: statusMap[status.id] ?? [])
        }.filter { !$0.projects.isEmpty }
    }

    var uncategorizedProjects: [Project] {
        projects.filter { $0.status == nil && $0.isFavorite != true }
    }

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            var queryItems: [URLQueryItem] = []
            if showArchived {
                queryItems.append(URLQueryItem(name: "is_archived", value: "true"))
            }
            async let projectsResponse: PaginatedResponse<Project> = api.request(.projects, queryItems: queryItems.isEmpty ? nil : queryItems)
            async let statusesResponse: PaginatedResponse<ProjectStatus> = api.request(.statuses)
            let (p, s) = try await (projectsResponse, statusesResponse)
            projects = p.results
            statuses = s.results
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createProject(title: String, statusId: Int?, teamId: Int) async {
        let request = ProjectCreateRequest(
            title: title,
            status: statusId,
            team: teamId
        )
        do {
            let _: Project = try await api.request(.createProject, body: request)
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteProject(_ project: Project) async {
        do {
            try await api.requestVoid(.deleteProject(id: project.id))
            projects.removeAll { $0.id == project.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFavorite(_ project: Project) async {
        do {
            let _: [String: Bool] = try await api.request(.favoriteProject(id: project.id))
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleArchive(_ project: Project) async {
        do {
            let _: [String: Bool] = try await api.request(.archiveProject(id: project.id))
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func duplicateProject(_ project: Project) async {
        do {
            let _: Project = try await api.request(.duplicateProject(id: project.id))
            await loadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
