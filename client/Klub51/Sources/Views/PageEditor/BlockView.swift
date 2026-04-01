import SwiftUI

struct BlockView: View {
    var block: PageBlock
    let onUpdate: (PageBlock) -> Void
    let onDelete: () -> Void
    let onInsertBelow: () -> Void

    @State private var isHovered = false
    @State private var text: String = ""

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            // Drag handle + menu (visible on hover)
            VStack(spacing: 2) {
                if isHovered {
                    Menu {
                        Button("Удалить", role: .destructive, action: onDelete)
                        Divider()
                        Button("Вставить блок ниже", action: onInsertBelow)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .frame(width: 20, height: 20)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                } else {
                    Color.clear.frame(width: 20, height: 20)
                }
            }
            .frame(width: 24)

            // Block content
            blockContent
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
        .onHover { isHovered = $0 }
        .onAppear { text = block.content.text ?? "" }
    }

    @ViewBuilder
    private var blockContent: some View {
        switch block.blockType {
        case .text:
            TextField("Текст...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .onChange(of: text) { _, newValue in
                    var updated = block
                    updated.content.text = newValue
                    onUpdate(updated)
                }

        case .heading1:
            TextField("Заголовок 1", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.title.bold())
                .onChange(of: text) { _, newValue in
                    var updated = block
                    updated.content.text = newValue
                    onUpdate(updated)
                }

        case .heading2:
            TextField("Заголовок 2", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.title2.bold())
                .onChange(of: text) { _, newValue in
                    var updated = block
                    updated.content.text = newValue
                    onUpdate(updated)
                }

        case .heading3:
            TextField("Заголовок 3", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.title3.bold())
                .onChange(of: text) { _, newValue in
                    var updated = block
                    updated.content.text = newValue
                    onUpdate(updated)
                }

        case .bulletList:
            HStack(alignment: .top, spacing: 6) {
                Text("•")
                    .foregroundStyle(.secondary)
                TextField("Пункт списка", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .onChange(of: text) { _, newValue in
                        var updated = block
                        updated.content.text = newValue
                        onUpdate(updated)
                    }
            }

        case .numberedList:
            HStack(alignment: .top, spacing: 6) {
                Text("\(block.order + 1).")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                TextField("Пункт списка", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .onChange(of: text) { _, newValue in
                        var updated = block
                        updated.content.text = newValue
                        onUpdate(updated)
                    }
            }

        case .todo:
            TodoBlockView(block: block, text: $text, onUpdate: onUpdate)

        case .quote:
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(.accent)
                    .frame(width: 3)
                TextField("Цитата...", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.body.italic())
                    .onChange(of: text) { _, newValue in
                        var updated = block
                        updated.content.text = newValue
                        onUpdate(updated)
                    }
            }
            .padding(.vertical, 4)

        case .code:
            TextField("Код...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .padding(12)
                .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
                .onChange(of: text) { _, newValue in
                    var updated = block
                    updated.content.text = newValue
                    onUpdate(updated)
                }

        case .divider:
            Divider()
                .padding(.vertical, 8)

        case .table:
            TableBlockView(block: block, onUpdate: onUpdate)

        case .image:
            if let urlString = block.content.url, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.fill.quaternary)
                        .frame(height: 200)
                        .overlay { Image(systemName: "photo").font(.title).foregroundStyle(.secondary) }
                }
                .frame(maxWidth: 600)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Todo Block

struct TodoBlockView: View {
    let block: PageBlock
    @Binding var text: String
    let onUpdate: (PageBlock) -> Void
    @State private var isChecked: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Toggle(isOn: $isChecked) {}
                .toggleStyle(.checkbox)
                .onChange(of: isChecked) { _, newValue in
                    var updated = block
                    updated.content.checked = newValue
                    onUpdate(updated)
                }

            TextField("Задача...", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .strikethrough(isChecked)
                .foregroundStyle(isChecked ? .secondary : .primary)
                .onChange(of: text) { _, newValue in
                    var updated = block
                    updated.content.text = newValue
                    onUpdate(updated)
                }
        }
        .onAppear { isChecked = block.content.checked ?? false }
    }
}

// MARK: - Table Block

struct TableBlockView: View {
    let block: PageBlock
    let onUpdate: (PageBlock) -> Void
    @State private var rows: [[String]] = [["", ""], ["", ""]]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(rows[rowIndex].indices, id: \.self) { colIndex in
                        TextField("", text: Binding(
                            get: { rows[rowIndex][colIndex] },
                            set: { newValue in
                                rows[rowIndex][colIndex] = newValue
                                var updated = block
                                updated.content.rows = rows
                                onUpdate(updated)
                            }
                        ))
                        .textFieldStyle(.plain)
                        .padding(8)
                        .frame(minWidth: 100)

                        if colIndex < rows[rowIndex].count - 1 {
                            Divider()
                        }
                    }
                }
                if rowIndex < rows.count - 1 {
                    Divider()
                }
            }
        }
        .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator))
        .onAppear {
            if let r = block.content.rows, !r.isEmpty {
                rows = r
            }
        }
    }
}
