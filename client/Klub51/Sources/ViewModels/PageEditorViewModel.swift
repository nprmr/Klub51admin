import Foundation

@MainActor
@Observable
final class PageEditorViewModel {
    var page: Page?
    var blocks: [PageBlock] = []
    var isLoading = false
    var errorMessage: String?

    private let api = APIClient.shared
    private var saveTask: Task<Void, Never>?
    let pageId: Int

    init(pageId: Int) {
        self.pageId = pageId
    }

    func loadPage() async {
        isLoading = true
        errorMessage = nil
        do {
            let loaded: Page = try await api.request(.pageDetail(id: pageId))
            page = loaded
            blocks = loaded.blocks ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updatePageTitle(_ title: String) async {
        struct Body: Encodable { let title: String }
        do {
            let updated: Page = try await api.request(.updatePage(id: pageId), body: Body(title: title))
            page = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addBlock(type: BlockType, after index: Int? = nil) async {
        let newOrder = (index ?? blocks.count - 1) + 1
        struct Body: Encodable {
            let page: Int
            let block_type: String
            let content: BlockContent
            let order: Int
        }
        let body = Body(
            page: pageId,
            block_type: type.rawValue,
            content: BlockContent(text: ""),
            order: newOrder
        )
        do {
            let block: PageBlock = try await api.request(.blocks, body: body)
            if let index {
                blocks.insert(block, at: min(index + 1, blocks.count))
            } else {
                blocks.append(block)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateBlock(_ block: PageBlock) {
        if let idx = blocks.firstIndex(where: { $0.id == block.id }) {
            blocks[idx] = block
        }
        debounceSave(block)
    }

    func deleteBlock(_ block: PageBlock) async {
        do {
            try await api.requestVoid(.deleteBlock(id: block.id))
            blocks.removeAll { $0.id == block.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reorderBlocks() async {
        struct Body: Encodable { let block_ids: [Int] }
        let ids = blocks.map(\.id)
        do {
            try await api.requestVoid(.reorderBlocks(pageId: pageId), body: Body(block_ids: ids))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveBlock(from source: IndexSet, to destination: Int) {
        blocks.move(fromOffsets: source, toOffset: destination)
        for (index, _) in blocks.enumerated() {
            blocks[index].order = index
        }
        Task { await reorderBlocks() }
    }

    // MARK: - Debounced save

    private func debounceSave(_ block: PageBlock) {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            struct Body: Encodable {
                let block_type: String
                let content: BlockContent
            }
            let body = Body(block_type: block.blockType.rawValue, content: block.content)
            try? await api.requestVoid(.updateBlock(id: block.id), body: body)
        }
    }
}
