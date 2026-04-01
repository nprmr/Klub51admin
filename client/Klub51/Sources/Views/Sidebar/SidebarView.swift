import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = ProjectListViewModel()
    @State private var showNewProject = false
    @State private var newProjectTitle = ""
    @Binding var selectedProjectId: Int?

    var body: some View {
        List(selection: $selectedProjectId) {
            // Grouped by status
            ForEach(viewModel.groupedProjects, id: \.status.id) { group in
                Section {
                    ForEach(group.projects) { project in
                        ProjectRowView(project: project)
                            .tag(project.id)
                            .contextMenu {
                                Button("Удалить", role: .destructive) {
                                    Task { await viewModel.deleteProject(project) }
                                }
                            }
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
                        ProjectRowView(project: project)
                            .tag(project.id)
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
            }

            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await viewModel.loadData() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
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
        .refreshable {
            await viewModel.loadData()
        }
    }
}
