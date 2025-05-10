import Foundation

/// Ошибки, возникающие при загрузке или парсинге текста
public enum FetchError: Error, LocalizedError, Equatable {
    /// Некорректный URL
    case badURL
    /// Не удалось получить данные (скачать HTML)
    case downloadFailed
    /// Не удалось декодировать данные
    case noData
    /// Не удалось распарсить HTML
    case parseError
    /// HTML скачан, но текст не извлечён (пустой)
    case emptyText

    /// Преобразует FetchError в локализуемую ошибку для пользователя
    public var userFacingError: UserFacingError {
        switch self {
        case .badURL, .downloadFailed:
            UserFacingError(
                messageKey: .errorDownloadFailed,
                adviceKey: .adviceCheckConnection
            )
        case .noData:
            UserFacingError(
                messageKey: .errorNoText,
                adviceKey: .adviceTryAgainLater
            )
        case .parseError:
            UserFacingError(
                messageKey: .errorParsing,
                adviceKey: .adviceTryAgainLater
            )
        case .emptyText:
            UserFacingError(
                messageKey: .errorExtractText,
                adviceKey: .adviceTryAgainLater
            )
        }
    }

    public var errorDescription: String? {
        switch self {
        case .badURL:
            "Некорректный URL"
        case .downloadFailed:
            "Не удалось скачать HTML"
        case .noData:
            "Не удалось декодировать данные"
        case .parseError:
            "Ошибка парсинга HTML"
        case .emptyText:
            "HTML скачан, но текст не извлечён (страница пуста или не содержит видимого текста)"
        }
    }
}
