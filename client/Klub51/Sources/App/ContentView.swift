import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedProjectId: Int?
    @State private var selectedPageId: Int?

    var body: some View {
        if appState.isAuthenticated {
            NavigationSplitView {
                SidebarView(selectedProjectId: $selectedProjectId)
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            Menu {
                                if let user = appState.currentUser {
                                    Text(user.displayName)
                                }
                                Divider()
                                Button("Выйти", role: .destructive) {
                                    appState.logout()
                                }
                            } label: {
                                Image(systemName: "person.circle")
                            }
                        }
                    }
            } detail: {
                if let projectId = selectedProjectId {
                    ProjectDetailView(projectId: projectId)
                } else {
                    ContentUnavailableView(
                        "Выберите проект",
                        systemImage: "sidebar.left",
                        description: Text("Выберите проект в боковой панели")
                    )
                }
            }
            .task {
                await appState.loadInitialData()
            }
        } else {
            LoginView()
        }
    }
}
