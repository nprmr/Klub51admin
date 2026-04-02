import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedProjectId: Int?
    @State private var selectedPageId: Int?
    @State private var showSearch = false
    @State private var showDomainAlerts = false

    var body: some View {
        Group {
            if !appState.isAuthenticated {
                LoginView()
            } else {
                switch appState.onboardingStep {
                case .completeProfile:
                    ProfileSetupView()
                case .createFirstProject:
                    CreateFirstProjectView()
                case .none:
                    mainContent
                }
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        NavigationSplitView {
            SidebarView(selectedProjectId: $selectedProjectId)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            showSearch = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                        .keyboardShortcut("k", modifiers: .command)
                    }

                    ToolbarItem(placement: .automatic) {
                        Button {
                            showDomainAlerts = true
                        } label: {
                            Image(systemName: "globe.badge.chevron.backward")
                        }
                    }

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
        .sheet(isPresented: $showSearch) {
            SearchSheet(selectedProjectId: $selectedProjectId)
        }
        .sheet(isPresented: $showDomainAlerts) {
            DomainAlertsView()
                .frame(minWidth: 600, minHeight: 400)
        }
        .task {
            await appState.loadInitialData()
        }
    }
}
