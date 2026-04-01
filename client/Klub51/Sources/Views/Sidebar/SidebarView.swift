import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ProjectListViewModel()
    @State private var showNewProject = false
    @State private var showArchived = false
    @State private var newProjectTitle = ""
    @Binding var selectedProjectId: Int?

    var body: some View {
        List(selection: $selectedProjectId) {
            // Favorites section
            let favorites = viewModel.projects.filter { $0.isFavorite == true }
            if !favorites.isEmpty {
                Section {
                    ForEach(favorites) { project in
                        projectRow(project)
                    }
                } header: {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text("Избранное")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Grouped by status
            ForEach(viewModel.groupedProjects, id: \.status.id) { group in
                Section {
                    ForEach(group.projects) { project in
                        projectRow(project)
                    }
                } header: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: group.status.color))
                            .frame(width: 8, height: 8)
                        Text(group.status.name)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Uncategorized
            if !viewModel.uncategorizedProjects.isEmpty {
                Section("Без статуса") {
                    ForEach(viewModel.uncategorizedProjects) { project in
                        projectRow(project)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Проекты")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewProject = true
                } label: {
                    Image(systemName: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            ToolbarItem(placement: .automatic) {
                Toggle(isOn: $showArchived) {
                    Image(systemName: "archivebox")
                }
                .toggleStyle(.button)
                .help("Показать архивные")
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await viewModel.loadData() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.projects.isEmpty {
                ProgressView()
            }
        }
        .alert("Новый проект", isPresented: $showNewProject) {
            TextField("Название", text: $newProjectTitle)
            Button("Создать") {
                guard !newProjectTitle.isEmpty, let teamId = appState.selectedTeamId else { return }
                Task {
                    await viewModel.createProject(
                        title: newProjectTitle,
                        statusId: viewModel.statuses.first?.id,
                        teamId: teamId
                    )
                    newProjectTitle = ""
                }
            }
            Button("Отмена", role: .cancel) {
                newProjectTitle = ""
            }
        }
        .task {
            await viewModel.loadData()
        }
        .onChange(of: showArchived) { _, show in
            viewModel.showArchived = show
            Task { await viewModel.loadData() }
        }
        .refreshable {
            await viewModel.loadData()
        }
    }

    @ViewBuilder
    private func projectRow(_ project: Project) -> some View {
        ProjectRowView(project: project)
            .tag(project.id)
            .contextMenu {
                Button {
                    Task { await viewModel.toggleFavorite(project) }
                } label: {
                    Label(
                        project.isFavorite == true ? "Убрать из избранного" : "В избранное",
                        systemImage: project.isFavorite == true ? "star.slash" : "star"
                    )
                }

                Button {
                    Task { await viewModel.toggleArchive(project) }
                } label: {
                    Label(
                        project.isArchived == true ? "Разархивировать" : "В архив",
                        systemImage: project.isArchived == true ? "tray.and.arrow.up" : "archivebox"
                    )
                }

                Button {
                    Task { await viewModel.duplicateProject(project) }
                } label: {
                    Label("Дублировать", systemImage: "doc.on.doc")
                }

                Divider()

                Button("Удалить", role: .destructive) {
                    Task { await viewModel.deleteProject(project) }
                }
            }
    }
}
