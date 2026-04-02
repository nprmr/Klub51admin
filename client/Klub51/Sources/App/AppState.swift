import Foundation

enum OnboardingStep: Equatable {
    case none
    case completeProfile   // after email OTP registration — ask name + password
    case createFirstProject // after social auth registration — go create project
}

@MainActor
@Observable
final class AppState {
    var isAuthenticated = false
    var currentUser: User?
    var teams: [Team] = []
    var selectedTeamId: Int?
    var onboardingStep: OnboardingStep = .none

    init() {
        isAuthenticated = KeychainHelper.shared.isAuthenticated
    }

    func handleAuthResponse(_ response: AuthTokenResponse) {
        KeychainHelper.shared.saveTokens(access: response.access, refresh: response.refresh)
        currentUser = response.user.toUser()
        isAuthenticated = true

        if response.isNew {
            if response.authProvider == "email" {
                onboardingStep = .completeProfile
            } else {
                onboardingStep = .createFirstProject
            }
        } else {
            onboardingStep = .none
        }
    }

    func completeOnboarding() {
        onboardingStep = .none
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
            logout()
        }
    }

    func logout() {
        KeychainHelper.shared.clearTokens()
        isAuthenticated = false
        currentUser = nil
        teams = []
        selectedTeamId = nil
        onboardingStep = .none
    }
}
