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
    /// Инициализатор контейнера параметров.
    /// - Parameters:
    ///   - targetLanguage: Целевой язык (по умолчанию пустая строка).
    ///   - complexityLevel: Уровень сложности (по умолчанию .schoolchild).
    ///   - detailLevel: Уровень детализации (по умолчанию .schoolchild).
    public init(targetLanguage: String = "", complexityLevel: ComplexityLevel = .schoolchild, detailLevel: DetailLevel = .schoolchild) {
        self.targetLanguage = targetLanguage
        self.complexityLevel = complexityLevel
        self.detailLevel = detailLevel
    }
}
