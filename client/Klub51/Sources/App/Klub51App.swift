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
        Settings {
            SettingsView()
                .environment(appState)
        }
        #endif
    }
}

// MARK: - Settings

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var serverURL = KeychainHelper.shared.serverURL

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
        .frame(width: 400, height: 250)
    }
}
