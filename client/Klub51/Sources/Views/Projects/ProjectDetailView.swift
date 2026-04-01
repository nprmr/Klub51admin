import SwiftUI

enum ProjectTab: String, CaseIterable {
    case card = "Карточка"
    case pages = "Страницы"
}

struct ProjectDetailView: View {
    let projectId: Int
    @State private var viewModel: ProjectDetailViewModel
    @State private var selectedTab: ProjectTab = .card
    @State private var selectedPageId: Int?
    @State private var showNewPage = false
    @State private var newPageTitle = ""

    init(projectId: Int) {
        self.projectId = projectId
        _viewModel = State(initialValue: ProjectDetailViewModel(projectId: projectId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.project == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let project = viewModel.project {
                VStack(spacing: 0) {
                    // Header
                    projectHeader(project)

                    // Tab picker
                    Picker("", selection: $selectedTab) {
                        ForEach(ProjectTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 12)

                    // Content
                    switch selectedTab {
                    case .card:
                        if let card = viewModel.card {
                            TechnicalCardView(card: card) { update in
                                Task { await viewModel.updateCard(update) }
                            }
                        } else {
                            ContentUnavailableView(
                                "Нет карточки",
                                systemImage: "doc.text",
                                description: Text("Техническая карточка загружается...")
                            )
                        }

                    case .pages:
                        pagesList
                    }
                }
            } else {
                ContentUnavailableView(
                    "Ошибка загрузки",
                    systemImage: "exclamationmark.triangle",
                    description: Text(viewModel.errorMessage ?? "")
                )
            }
        }
        .task(id: projectId) {
            viewModel = ProjectDetailViewModel(projectId: projectId)
            await viewModel.loadAll()
        }
        .navigationTitle(viewModel.project?.title ?? "Проект")
    }

    // MARK: - Subviews

    @ViewBuilder
    private func projectHeader(_ project: Project) -> some View {
        HStack(spacing: 12) {
            Text(project.icon.isEmpty ? "📁" : project.icon)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 4) {
                Text(project.title)
                    .font(.title2.bold())

                HStack(spacing: 8) {
                    if let statusName = project.statusName,
                       let statusColor = project.statusColor {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: statusColor))
                                .frame(width: 8, height: 8)
                            Text(statusName)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.fill.quaternary, in: Capsule())
                    }

                    if !project.description.isEmpty {
                        Text(project.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private var pagesList: some View {
        if viewModel.pages.isEmpty {
            ContentUnavailableView(
                "Нет страниц",
                systemImage: "doc.text",
                description: Text("Создайте первую страницу")
            )
            .overlay(alignment: .bottom) {
                Button("Создать страницу") { showNewPage = true }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom, 40)
            }
        } else {
            List(selection: $selectedPageId) {
                ForEach(viewModel.pages) { page in
                    NavigationLink(value: page.id) {
                        HStack(spacing: 8) {
                            Text(page.icon.isEmpty ? "📄" : page.icon)
                            Text(page.title)
                                .lineLimit(1)
                            Spacer()
                            if let count = page.childrenCount, count > 0 {
                                Text("\(count)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.fill.quaternary, in: Capsule())
                            }
                        }
                    }
                    .contextMenu {
                        Button("Удалить", role: .destructive) {
                            Task { await viewModel.deletePage(page) }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewPage = true
                    } label: {
                        Image(systemName: "doc.badge.plus")
                    }
                }
            }
        }
        alert("Новая страница", isPresented: $showNewPage) {
            TextField("Название", text: $newPageTitle)
            Button("Создать") {
                guard !newPageTitle.isEmpty else { return }
                Task {
                    await viewModel.createPage(title: newPageTitle)
                    newPageTitle = ""
                }
            }
            Button("Отмена", role: .cancel) {
                newPageTitle = ""
            }
        }
    }
}
