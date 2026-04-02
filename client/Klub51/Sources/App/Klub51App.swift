import SwiftUI

@main
struct Klub51App: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 800, minHeight: 500)
        }
        .windowStyle(.automatic)
        .defaultSize(width: 1100, height: 700)
        #if os(macOS)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Новый проект") {
                    NotificationCenter.default.post(name: .newProjectShortcut, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])

                Button("Поиск") {
                    NotificationCenter.default.post(name: .searchShortcut, object: nil)
                }
                .keyboardShortcut("k", modifiers: .command)
            }
        }
        #endif

        #if os(macOS)
        Settings {
            SettingsView()
                .environment(appState)
        }
        #endif
    }
}

// MARK: - Notification names for keyboard shortcuts

extension Notification.Name {
    static let newProjectShortcut = Notification.Name("newProjectShortcut")
    static let searchShortcut = Notification.Name("searchShortcut")
}

// MARK: - Settings

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var serverURL = KeychainHelper.shared.serverURL
    @State private var connectedAccounts: [[String: Any]] = []

    var body: some View {
        Form {
            Section("Сервер") {
                TextField("URL сервера", text: $serverURL)
                    .onSubmit {
                        KeychainHelper.shared.serverURL = serverURL
                    }
            }

            Section("Аккаунт") {
                if let user = appState.currentUser {
                    LabeledContent("Пользователь", value: user.displayName)
                    LabeledContent("Email", value: user.email)
                }
                Button("Выйти", role: .destructive) {
                    appState.logout()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 300)
    }
}
