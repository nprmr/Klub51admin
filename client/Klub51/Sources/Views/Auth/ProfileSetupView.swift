import SwiftUI

struct ProfileSetupView: View {
    @Environment(AppState.self) private var appState
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(.accent)

                Text("Заполните профиль")
                    .font(.largeTitle.bold())

                Text("Расскажите немного о себе")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
                .frame(height: 40)

            VStack(spacing: 16) {
                TextField("Имя", text: $firstName)
                    .textFieldStyle(.roundedBorder)

                TextField("Фамилия", text: $lastName)
                    .textFieldStyle(.roundedBorder)

                SecureField("Пароль (мин. 8 символов)", text: $password)
                    .textFieldStyle(.roundedBorder)

                SecureField("Подтвердите пароль", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await save() } }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button(action: { Task { await save() } }) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Продолжить")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isValid || isLoading)

                Button("Пропустить") {
                    appState.onboardingStep = .createFirstProject
                }
                .buttonStyle(.borderless)
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 360)

            Spacer()
        }
        .padding(40)
        .frame(minWidth: 480, minHeight: 550)
    }

    private var isValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty
        && (password.isEmpty || (password.count >= 8 && password == confirmPassword))
    }

    private func save() async {
        guard isValid else { return }

        if !password.isEmpty && password != confirmPassword {
            errorMessage = "Пароли не совпадают"
            return
        }

        isLoading = true
        errorMessage = nil

        let request = CompleteProfileRequest(
            firstName: firstName,
            lastName: lastName,
            password: password.isEmpty ? nil : password
        )

        do {
            let response: CompleteProfileResponse = try await APIClient.shared.request(
                .completeProfile,
                body: request
            )
            appState.currentUser = response.user.toUser()
            appState.onboardingStep = .createFirstProject
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
