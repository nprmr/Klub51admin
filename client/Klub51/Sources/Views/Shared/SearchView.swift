import SwiftUI

struct SearchSheet: View {
    @State private var viewModel = SearchViewModel()
    @Binding var selectedProjectId: Int?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Поиск проектов и страниц...", text: $viewModel.query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .onSubmit { viewModel.search() }

                if !viewModel.query.isEmpty {
                    Button {
                        viewModel.clear()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()

            Divider()

            // Results
            if viewModel.isSearching {
                Spacer()
                ProgressView()
                Spacer()
            } else if let results = viewModel.results {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !results.projects.isEmpty {
                            Section {
                                ForEach(results.projects) { project in
                                    Button {
                                        selectedProjectId = project.id
                                        dismiss()
                                    } label: {
                                        HStack(spacing: 8) {
                                            Text(project.icon.isEmpty ? "📁" : project.icon)
                                            VStack(alignment: .leading) {
                                                Text(project.title)
                                                    .font(.body)
                                                if let status = project.statusName {
                                                    Text(status)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            Spacer()
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.vertical, 4)
                                }
                            } header: {
                                Text("Проекты")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if !results.pages.isEmpty {
                            Section {
                                ForEach(results.pages) { page in
                                    HStack(spacing: 8) {
                                        Text(page.icon.isEmpty ? "📄" : page.icon)
                                        Text(page.title)
                                            .font(.body)
                                    }
                                    .padding(.vertical, 4)
                                }
                            } header: {
                                Text("Страницы")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                }
            } else {
                Spacer()
                if viewModel.query.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Начните вводить для поиска")
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .onChange(of: viewModel.query) { _, _ in
            viewModel.search()
        }
    }
}
