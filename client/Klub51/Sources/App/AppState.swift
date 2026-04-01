import Foundation

@MainActor
@Observable
final class AppState {
    var isAuthenticated = false
    var currentUser: User?
    var teams: [Team] = []
    var selectedTeamId: Int?

    init() {
        isAuthenticated = KeychainHelper.shared.isAuthenticated
    }

    func loadInitialData() async {
        guard isAuthenticated else { return }
        do {
            let user: User = try await APIClient.shared.request(.me)
            currentUser = user

            let teamsResponse: PaginatedResponse<Team> = try await APIClient.shared.request(.teams)
            teams = teamsResponse.results
            selectedTeamId = teams.first?.id
        } catch {
            // Token might be expired
            logout()
        }
    }

    func logout() {
        KeychainHelper.shared.clearTokens()
        isAuthenticated = false
        currentUser = nil
        teams = []
        selectedTeamId = nil
    }
}
