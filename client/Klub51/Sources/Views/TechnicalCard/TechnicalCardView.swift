import SwiftUI

struct TechnicalCardView: View {
    let card: TechnicalCard
    let onSave: (TechnicalCardUpdate) -> Void

    @State private var githubUrl: String = ""
    @State private var appstoreUrl: String = ""
    @State private var figmaUrl: String = ""
    @State private var domainName: String = ""
    @State private var domainRegistrar: String = ""
    @State private var domainExpires: String = ""
    @State private var budgetRequired: String = ""
    @State private var budgetCurrency: String = "RUB"
    @State private var adCabinetUrl: String = ""
    @State private var notes: String = ""
    @State private var hasChanges = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Links section
                cardSection("Ссылки") {
                    LinkField(title: "GitHub", url: $githubUrl, icon: "chevron.left.forwardslash.chevron.right")
                    LinkField(title: "App Store", url: $appstoreUrl, icon: "app.badge")
                    LinkField(title: "Figma", url: $figmaUrl, icon: "paintbrush")
                    LinkField(title: "Рекламный кабинет", url: $adCabinetUrl, icon: "megaphone")
                }

                // Domain section
                cardSection("Домен") {
                    LabeledField(title: "Домен", text: $domainName)
                    LabeledField(title: "Регистратор", text: $domainRegistrar)
                    LabeledField(title: "Истекает", text: $domainExpires)
                }

                // Budget section
                cardSection("Бюджет") {
                    HStack(spacing: 12) {
                        LabeledField(title: "Сумма", text: $budgetRequired)
                        LabeledField(title: "Валюта", text: $budgetCurrency)
                            .frame(width: 80)
                    }
                }

                // Notes
                cardSection("Заметки") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
                }

                // Custom fields
                if let fields = card.customFields, !fields.isEmpty {
                    cardSection("Дополнительно") {
                        ForEach(fields) { field in
                            LabeledContent(field.label) {
                                if field.fieldType == "url" {
                                    Link(field.value, destination: URL(string: field.value) ?? URL(string: "about:blank")!)
                                        .font(.body)
                                } else {
                                    Text(field.value)
                                        .font(.body)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear { populateFields() }
        .onChange(of: githubUrl) { _, _ in hasChanges = true }
        .onChange(of: appstoreUrl) { _, _ in hasChanges = true }
        .onChange(of: figmaUrl) { _, _ in hasChanges = true }
        .onChange(of: domainName) { _, _ in hasChanges = true }
        .onChange(of: domainRegistrar) { _, _ in hasChanges = true }
        .onChange(of: domainExpires) { _, _ in hasChanges = true }
        .onChange(of: budgetRequired) { _, _ in hasChanges = true }
        .onChange(of: budgetCurrency) { _, _ in hasChanges = true }
        .onChange(of: adCabinetUrl) { _, _ in hasChanges = true }
        .onChange(of: notes) { _, _ in hasChanges = true }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Сохранить") { saveCard() }
                    .disabled(!hasChanges)
            }
        }
    }

    // MARK: - Helpers

    private func populateFields() {
        githubUrl = card.githubUrl
        appstoreUrl = card.appstoreUrl
        figmaUrl = card.figmaUrl
        domainName = card.domainName
        domainRegistrar = card.domainRegistrar
        domainExpires = card.domainExpires ?? ""
        budgetRequired = card.budgetRequired ?? ""
        budgetCurrency = card.budgetCurrency
        adCabinetUrl = card.adCabinetUrl
        notes = card.notes
        hasChanges = false
    }

    private func saveCard() {
        let update = TechnicalCardUpdate(
            githubUrl: githubUrl,
            appstoreUrl: appstoreUrl,
            figmaUrl: figmaUrl,
            domainName: domainName,
            domainRegistrar: domainRegistrar,
            domainExpires: domainExpires.isEmpty ? nil : domainExpires,
            budgetRequired: budgetRequired.isEmpty ? nil : budgetRequired,
            budgetCurrency: budgetCurrency,
            adCabinetUrl: adCabinetUrl,
            notes: notes
        )
        onSave(update)
        hasChanges = false
    }

    @ViewBuilder
    private func cardSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(spacing: 10) {
                content()
            }
        }
    }
}

// MARK: - Reusable fields

struct LinkField: View {
    let title: String
    @Binding var url: String
    var icon: String = "link"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)

            TextField("https://...", text: $url)
                .textFieldStyle(.roundedBorder)

            if let validURL = URL(string: url), !url.isEmpty {
                Button {
                    #if os(macOS)
                    NSWorkspace.shared.open(validURL)
                    #endif
                } label: {
                    Image(systemName: "arrow.up.right.square")
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

struct LabeledField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)

            TextField("...", text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
