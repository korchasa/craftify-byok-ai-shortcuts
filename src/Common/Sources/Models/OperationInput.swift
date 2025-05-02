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
    /// Диапазон количества предложений для операций суммаризации.
    public var sentenceCountRange: SentenceCountRange
    /// Инициализатор контейнера параметров.
    /// - Parameters:
    ///   - targetLanguage: Целевой язык (по умолчанию пустая строка).
    ///   - complexityLevel: Уровень сложности (по умолчанию .schoolchild).
    ///   - detailLevel: Уровень детализации (по умолчанию .schoolchild).
    ///   - sentenceCountRange: Диапазон количества предложений (по умолчанию .twoToThree).
    public init(targetLanguage: String = "", complexityLevel: ComplexityLevel = .schoolchild, detailLevel: DetailLevel = .schoolchild, sentenceCountRange: SentenceCountRange = .twoToThree) {
        self.targetLanguage = targetLanguage
        self.complexityLevel = complexityLevel
        self.detailLevel = detailLevel
        self.sentenceCountRange = sentenceCountRange
    }
}
