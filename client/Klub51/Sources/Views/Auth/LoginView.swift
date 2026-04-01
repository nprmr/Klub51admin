import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var serverURL = KeychainHelper.shared.serverURL
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Logo
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.accent)

                Text("Klub51")
                    .font(.largeTitle.bold())

                Text("Управление проектами")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
                .frame(height: 40)

            // Form
            VStack(spacing: 16) {
                TextField("Адрес сервера", text: $serverURL)
                    .textFieldStyle(.roundedBorder)

                TextField("Логин", text: $username)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif

                SecureField("Пароль", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await login() } }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button(action: { Task { await login() } }) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Войти")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(username.isEmpty || password.isEmpty || isLoading)
            }
            .frame(maxWidth: 320)

            Spacer()
        }
        .padding(40)
        .frame(minWidth: 480, minHeight: 500)
    }

    private func login() async {
        isLoading = true
        errorMessage = nil
        KeychainHelper.shared.serverURL = serverURL

        struct LoginBody: Encodable {
            let username: String
            let password: String
        }

        do {
            let response: AuthTokenResponse = try await APIClient.shared.request(
                .login(username: username, password: password),
                body: LoginBody(username: username, password: password)
            )
            KeychainHelper.shared.saveTokens(access: response.access, refresh: response.refresh)

            let user: User = try await APIClient.shared.request(.me)
            appState.currentUser = user
            appState.isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
