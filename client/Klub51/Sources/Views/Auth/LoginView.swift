import SwiftUI
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

struct LoginView: View {
    @Environment(AppState.self) private var appState
    @State private var serverURL = KeychainHelper.shared.serverURL
    @State private var email = ""
    @State private var otpCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var otpSent = false
    @State private var cooldownRemaining = 0

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            VStack(spacing: 24) {
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

            // Auth form
            VStack(spacing: 16) {
                TextField("Адрес сервера", text: $serverURL)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: serverURL) {
                        KeychainHelper.shared.serverURL = serverURL
                    }

                if !otpSent {
                    emailStep
                } else {
                    otpStep
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: 320)

            Spacer()
                .frame(height: 32)

            // Social auth
            socialAuthSection
                .frame(maxWidth: 320)

            Spacer()
        }
        .padding(40)
        .frame(minWidth: 480, minHeight: 600)
        .onReceive(timer) { _ in
            if cooldownRemaining > 0 {
                cooldownRemaining -= 1
            }
        }
    }

    // MARK: - Email step

    @ViewBuilder
    private var emailStep: some View {
        TextField("Email", text: $email)
            .textFieldStyle(.roundedBorder)
            #if os(iOS)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            #endif
            .onSubmit { Task { await requestOTP() } }

        Button(action: { Task { await requestOTP() } }) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
            } else {
                Text("Получить код")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(email.isEmpty || isLoading)
    }

    // MARK: - OTP step

    @ViewBuilder
    private var otpStep: some View {
        HStack {
            Text(email)
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Изменить") {
                withAnimation { otpSent = false; otpCode = "" }
            }
            .font(.callout)
        }

        TextField("Код из письма", text: $otpCode)
            .textFieldStyle(.roundedBorder)
            #if os(iOS)
            .keyboardType(.numberPad)
            #endif
            .onSubmit { Task { await verifyOTP() } }

        Button(action: { Task { await verifyOTP() } }) {
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
        .disabled(otpCode.count != 6 || isLoading)

        Button(action: { Task { await requestOTP() } }) {
            if cooldownRemaining > 0 {
                Text("Отправить повторно (\(cooldownRemaining)с)")
            } else {
                Text("Отправить повторно")
            }
        }
        .buttonStyle(.borderless)
        .font(.callout)
        .disabled(cooldownRemaining > 0 || isLoading)
    }

    // MARK: - Social auth section

    @ViewBuilder
    private var socialAuthSection: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.separator)
                Text("или")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.separator)
            }

            #if canImport(AuthenticationServices)
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.email, .fullName]
            } onCompletion: { result in
                Task { await handleAppleSignIn(result) }
            }
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 44)
            #endif

            Button(action: { Task { await signInWithGitHub() } }) {
                HStack {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                    Text("Войти через GitHub")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button(action: { Task { await signInWithGoogle() } }) {
                HStack {
                    Image(systemName: "globe")
                    Text("Войти через Google")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
    }

    // MARK: - OTP actions

    private func requestOTP() async {
        isLoading = true
        errorMessage = nil
        KeychainHelper.shared.serverURL = serverURL

        struct OTPBody: Encodable { let email: String }

        do {
            let _: OTPRequestResponse = try await APIClient.shared.request(
                .otpRequest,
                body: OTPBody(email: email)
            )
            withAnimation { otpSent = true }
            cooldownRemaining = 60
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func verifyOTP() async {
        isLoading = true
        errorMessage = nil

        struct VerifyBody: Encodable {
            let email: String
            let code: String
        }

        do {
            let response: AuthTokenResponse = try await APIClient.shared.request(
                .otpVerify,
                body: VerifyBody(email: email, code: otpCode)
            )
            KeychainHelper.shared.saveTokens(access: response.access, refresh: response.refresh)
            appState.currentUser = response.user
            appState.isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Social auth actions

    #if canImport(AuthenticationServices)
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let idTokenData = credential.identityToken,
                  let idToken = String(data: idTokenData, encoding: .utf8) else {
                errorMessage = "Не удалось получить данные Apple ID"
                return
            }

            struct AppleBody: Encodable {
                let id_token: String
                let first_name: String
                let last_name: String
            }

            isLoading = true
            errorMessage = nil
            do {
                let response: AuthTokenResponse = try await APIClient.shared.request(
                    .socialApple,
                    body: AppleBody(
                        id_token: idToken,
                        first_name: credential.fullName?.givenName ?? "",
                        last_name: credential.fullName?.familyName ?? ""
                    )
                )
                KeychainHelper.shared.saveTokens(access: response.access, refresh: response.refresh)
                appState.currentUser = response.user
                appState.isAuthenticated = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }
    }
    #endif

    private func signInWithGitHub() async {
        // TODO: Implement GitHub OAuth via ASWebAuthenticationSession
        errorMessage = "GitHub OAuth — в разработке"
    }

    private func signInWithGoogle() async {
        // TODO: Implement Google OAuth via ASWebAuthenticationSession
        errorMessage = "Google OAuth — в разработке"
    }
}
