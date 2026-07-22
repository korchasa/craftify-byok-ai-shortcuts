import Foundation

/// Универсальный контейнер параметров для всех операций Craftify.
/// Используется для передачи параметров между ViewModel и реализациями OperationType.
public struct OperationInput {
    /// Целевой язык для операций перевода.
    public var targetLanguage: String
    /// Уровень сложности для операций упрощения (не используется в UI).
    public var complexityLevel: ComplexityLevel = .schoolchild
    /// Уровень детализации для операций объяснения (не используется в UI).
    public var detailLevel: DetailLevel = .schoolchild
    /// Длина итогового текста для операций суммаризации.
    public var length: String
    /// URL для загрузки текста (опционально, только для summarize)
    public var url: String?
    /// Текст для обработки (опционально, только для summarize)
    public var text: String?
    /// Инициализатор контейнера параметров.
    /// - Parameters:
    ///   - targetLanguage: Целевой язык (по умолчанию пустая строка).
    ///   - complexityLevel: Уровень сложности для операций упрощения (не используется в UI).
    ///   - detailLevel: Уровень детализации для операций объяснения (не используется в UI).
    ///   - length: Длина итогового текста (по умолчанию SummarizeLengths.defaultLength).
    ///   - url: URL для загрузки текста (по умолчанию nil)
    ///   - text: Текст для обработки (по умолчанию nil)
    public init(targetLanguage: String = "", complexityLevel: ComplexityLevel = .schoolchild, detailLevel: DetailLevel = .schoolchild, length: String = SummarizeLengths.defaultLength, url: String? = nil, text: String? = nil) {
        self.targetLanguage = targetLanguage
        self.complexityLevel = complexityLevel
        self.detailLevel = detailLevel
        self.length = length
        self.url = url
        self.text = text
    }

    /// Проверяет, является ли строка HTTP(S) URL.
    /// - Parameter string: Строка для проверки.
    /// - Returns: true, если строка — http/https URL, иначе false.
    public static func isHttpURL(string: String) -> Bool {
        guard let parsedURL = URL(string: string), let scheme = parsedURL.scheme else { return false }
        return scheme.hasPrefix("http")
    }
}
