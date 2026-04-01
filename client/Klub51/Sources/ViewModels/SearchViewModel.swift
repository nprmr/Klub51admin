import Foundation

@MainActor
@Observable
final class SearchViewModel {
    var query = ""
    var results: SearchResponse?
    var isSearching = false

    private let api = APIClient.shared
    private var searchTask: Task<Void, Never>?

    var hasResults: Bool {
        guard let results else { return false }
        return !results.projects.isEmpty || !results.pages.isEmpty
    }

    func search() {
        searchTask?.cancel()
        guard query.count >= 2 else {
            results = nil
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            isSearching = true
            do {
                let response: SearchResponse = try await api.request(
                    .search,
                    queryItems: [URLQueryItem(name: "q", value: query)]
                )
                if !Task.isCancelled {
                    results = response
                }
            } catch {
                // silently fail search
            }
            isSearching = false
        }
    }

    func clear() {
        query = ""
        results = nil
        searchTask?.cancel()
    }
}
