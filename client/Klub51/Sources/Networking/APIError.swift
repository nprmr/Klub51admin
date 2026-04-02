import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)
    case tokenExpired

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Неверный URL сервера"
        case .unauthorized:
            "Сессия истекла или неверные данные"
        case .forbidden:
            "Нет доступа"
        case .notFound:
            "Не найдено"
        case .serverError(let code):
            "Ошибка сервера (\(code))"
        case .decodingError:
            "Ошибка обработки данных"
        case .networkError:
            "Нет соединения с сервером"
        case .tokenExpired:
            "Сессия истекла, войдите снова"
        }
    }
}
