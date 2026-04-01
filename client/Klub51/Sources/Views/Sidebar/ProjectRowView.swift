import SwiftUI

struct ProjectRowView: View {
    let project: Project

    var body: some View {
        HStack(spacing: 8) {
            Text(project.icon.isEmpty ? "📁" : project.icon)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(project.title)
                    .font(.body)
                    .lineLimit(1)

                if let pageCount = project.pageCount, pageCount > 0 {
                    Text("\(pageCount) стр.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
