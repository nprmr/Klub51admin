import Foundation

@MainActor
@Observable
final class APIClient {
    static let shared = APIClient()

    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()

    private var baseURL: URL {
        URL(string: KeychainHelper.shared.serverURL)!
    }

    // MARK: - Generic request

    func request<T: Decodable & Sendable>(
        _ endpoint: APIEndpoint,
        body: (any Encodable & Sendable)? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let data = try await performRequest(endpoint, body: body, queryItems: queryItems)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func requestVoid(
        _ endpoint: APIEndpoint,
        body: (any Encodable & Sendable)? = nil
    ) async throws {
        _ = try await performRequest(endpoint, body: body)
    }

    // MARK: - Private

    private func performRequest(
        _ endpoint: APIEndpoint,
        body: (any Encodable & Sendable)? = nil,
        queryItems: [URLQueryItem]? = nil,
        isRetry: Bool = false
    ) async throws -> Data {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = endpoint.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainHelper.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        switch httpResponse.statusCode {
        case 200...299:
            return data
        case 401:
            if !isRetry, let refresh = KeychainHelper.shared.refreshToken {
                let refreshed = try await refreshAccessToken(refresh: refresh)
                if refreshed {
                    return try await performRequest(endpoint, body: body, queryItems: queryItems, isRetry: true)
                }
            }
            KeychainHelper.shared.clearTokens()
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    private func refreshAccessToken(refresh: String) async throws -> Bool {
        struct RefreshRequest: Encodable { let refresh: String }
        struct RefreshResponse: Decodable { let access: String }

        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("/api/auth/refresh/"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try encoder.encode(RefreshRequest(refresh: refresh))

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return false
        }

        let decoded = try decoder.decode(RefreshResponse.self, from: data)
        KeychainHelper.shared.accessToken = decoded.access
        return true
    }
}

// MARK: - Type erasure for Encodable

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ wrapped: any Encodable) {
        _encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
