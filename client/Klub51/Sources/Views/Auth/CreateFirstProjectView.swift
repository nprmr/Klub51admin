import SwiftUI

struct CreateFirstProjectView: View {
    @Environment(AppState.self) private var appState
    @State private var projectTitle = ""
    @State private var projectIcon = "📁"
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let icons = ["📁", "🚀", "💼", "🎨", "📱", "🌐", "🛒", "📊", "🎮", "🏠", "📝", "⚡"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(.accent)

                Text("Создайте первый проект")
                    .font(.largeTitle.bold())

                if let user = appState.currentUser {
                    Text("Добро пожаловать, \(user.displayName)!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
                .frame(height: 40)

            VStack(spacing: 20) {
                // Icon picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Иконка")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(40)), count: 6), spacing: 8) {
                        ForEach(icons, id: \.self) { icon in
                            Button(icon) {
                                projectIcon = icon
                            }
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(projectIcon == icon ? Color.accentColor.opacity(0.15) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(projectIcon == icon ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                            .buttonStyle(.plain)
                        }
                    }
                }

                TextField("Название проекта", text: $projectTitle)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await createProject() } }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button(action: { Task { await createProject() } }) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Создать проект")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(projectTitle.isEmpty || isLoading)

                Button("Пропустить") {
                    appState.completeOnboarding()
                }
                .buttonStyle(.borderless)
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 360)

            Spacer()
        }
        .padding(40)
        .frame(minWidth: 480, minHeight: 600)
        .task {
            await appState.loadInitialData()
        }
    }

    private func createProject() async {
        guard !projectTitle.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        // Ensure we have a team
        if appState.teams.isEmpty {
            // Create a default team
            struct TeamBody: Encodable { let name: String }
            do {
                let team: Team = try await APIClient.shared.request(
                    .teams,
                    body: TeamBody(name: "Мои проекты")
                )
                appState.teams = [team]
                appState.selectedTeamId = team.id
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
                return
            }
        }

        guard let teamId = appState.selectedTeamId ?? appState.teams.first?.id else {
            errorMessage = "Не удалось создать команду"
            isLoading = false
            return
        }

        let request = ProjectCreateRequest(
            title: projectTitle,
            icon: projectIcon,
            team: teamId
        )

        do {
            let _: Project = try await APIClient.shared.request(.createProject, body: request)
            appState.completeOnboarding()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
