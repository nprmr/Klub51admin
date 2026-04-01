import SwiftUI

struct PageEditorView: View {
    let pageId: Int
    @State private var viewModel: PageEditorViewModel
    @State private var editingTitle: String = ""
    @State private var showBlockPicker = false

    init(pageId: Int) {
        self.pageId = pageId
        _viewModel = State(initialValue: PageEditorViewModel(pageId: pageId))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.page == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Page title
                        TextField("Без названия", text: $editingTitle)
                            .font(.largeTitle.bold())
                            .textFieldStyle(.plain)
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 12)
                            .onSubmit {
                                Task { await viewModel.updatePageTitle(editingTitle) }
                            }

                        // Blocks
                        ForEach(Array(viewModel.blocks.enumerated()), id: \.element.id) { index, block in
                            BlockView(
                                block: block,
                                onUpdate: { updated in viewModel.updateBlock(updated) },
                                onDelete: { Task { await viewModel.deleteBlock(block) } },
                                onInsertBelow: { Task { await viewModel.addBlock(type: .text, after: index) } }
                            )
                        }
                        .onMove { source, destination in
                            viewModel.moveBlock(from: source, to: destination)
                        }

                        // Add block button
                        Button {
                            showBlockPicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle")
                                Text("Добавить блок")
                            }
                            .font(.body)
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .padding()
                        .popover(isPresented: $showBlockPicker) {
                            BlockTypePicker { type in
                                showBlockPicker = false
                                Task { await viewModel.addBlock(type: type) }
                            }
                        }

                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .task(id: pageId) {
            viewModel = PageEditorViewModel(pageId: pageId)
            await viewModel.loadPage()
            editingTitle = viewModel.page?.title ?? ""
        }
        .navigationTitle(viewModel.page?.title ?? "Страница")
    }
}

// MARK: - Block Type Picker

struct BlockTypePicker: View {
    let onSelect: (BlockType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Тип блока")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ForEach(BlockType.allCases, id: \.self) { type in
                Button {
                    onSelect(type)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: type.systemImage)
                            .frame(width: 20)
                        Text(type.displayName)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 220)
        .padding(.vertical, 8)
    }
}
