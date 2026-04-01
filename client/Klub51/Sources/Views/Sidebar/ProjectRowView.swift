import SwiftUI

struct ProjectRowView: View {
    let project: Project

    var body: some View {
        HStack(spacing: 8) {
            Text(project.icon.isEmpty ? "📁" : project.icon)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(project.title)
                        .font(.body)
                        .lineLimit(1)

                    if project.isFavorite == true {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                    }

                    if project.isArchived == true {
                        Image(systemName: "archivebox")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if let pageCount = project.pageCount, pageCount > 0 {
                    Text("\(pageCount) стр.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
        .opacity(project.isArchived == true ? 0.6 : 1.0)
    }
}
