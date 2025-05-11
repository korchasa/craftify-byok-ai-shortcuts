import Foundation

/// Универсальный контейнер параметров для всех операций Craftify.
/// Используется для передачи параметров между ViewModel и реализациями OperationType.
public struct OperationInput {
    /// Целевой язык для операций перевода.
    public var targetLanguage: String
    /// Уровень сложности для операций упрощения.
    public var complexityLevel: ComplexityLevel
    /// Уровень детализации для операций объяснения.
    public var detailLevel: DetailLevel
    /// Длина итогового текста для операций суммаризации.
    public var length: String
    /// URL для загрузки текста (опционально, только для summarize)
    public var url: String?
    /// Текст для обработки (опционально, только для summarize)
    public var text: String?
    /// Инициализатор контейнера параметров.
    /// - Parameters:
    ///   - targetLanguage: Целевой язык (по умолчанию пустая строка).
    ///   - complexityLevel: Уровень сложности (по умолчанию .schoolchild).
    ///   - detailLevel: Уровень детализации (по умолчанию .schoolchild).
    ///   - length: Длина итогового текста (по умолчанию "2-3 sentences").
    ///   - url: URL для загрузки текста (по умолчанию nil)
    ///   - text: Текст для обработки (по умолчанию nil)
    public init(targetLanguage: String = "", complexityLevel: ComplexityLevel = .schoolchild, detailLevel: DetailLevel = .schoolchild, length: String = "2-3 sentences", url: String? = nil, text: String? = nil) {
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
        guard let url = URL(string: string), let scheme = url.scheme else { return false }
        return scheme.hasPrefix("http")
    }
}
