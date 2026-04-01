import SwiftUI

struct DomainAlertsView: View {
    @State private var alerts: [DomainAlert] = []
    @State private var isLoading = false
    @State private var days = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Истечение доменов")
                    .font(.headline)
                Spacer()
                Picker("Период", selection: $days) {
                    Text("7 дней").tag(7)
                    Text("30 дней").tag(30)
                    Text("90 дней").tag(90)
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }
            .padding()

            Divider()

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if alerts.isEmpty {
                ContentUnavailableView(
                    "Всё в порядке",
                    systemImage: "checkmark.circle",
                    description: Text("Нет доменов, истекающих в ближайшие \(days) дней")
                )
            } else {
                List(alerts) { alert in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(alert.domainName)
                                .font(.body.bold())
                            Text(alert.projectTitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Регистратор: \(alert.domainRegistrar)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            if alert.isExpired {
                                Text("ИСТЁК")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.red, in: Capsule())
                            } else if alert.daysLeft <= 7 {
                                Text("\(alert.daysLeft) дн.")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.orange, in: Capsule())
                            } else {
                                Text("\(alert.daysLeft) дн.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(alert.domainExpires)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .task(id: days) {
            await loadAlerts()
        }
    }

    private func loadAlerts() async {
        isLoading = true
        do {
            alerts = try await APIClient.shared.request(
                .domainsExpiring,
                queryItems: [URLQueryItem(name: "days", value: "\(days)")]
            )
        } catch {
            alerts = []
        }
        isLoading = false
    }
}
