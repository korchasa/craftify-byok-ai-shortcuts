import Foundation

/// Операция инвентаря Craftify (тип, параметры, шаблон промпта)
public struct InventoryOperation: Codable, Equatable, Hashable {
    /// Тип операции (translate, simplify, correct, explain)
    public let operation: OperationType
    /// Сериализованные параметры операции
    public let params: Data // Encoded params (type depends on operation)
    /// Шаблон промпта для LLM
    public let promptTemplate: String

    public func hash(into hasher: inout Hasher) {
        hasher.combine(operation)
        hasher.combine(params.hashValue)
        hasher.combine(promptTemplate)
    }

    /// Инициализация InventoryOperation
    /// - Parameters:
    ///   - operation: Тип операции
    ///   - params: Сериализованные параметры
    ///   - promptTemplate: Шаблон промпта
    public init(operation: OperationType, params: Data, promptTemplate: String) {
        self.operation = operation
        self.params = params
        self.promptTemplate = promptTemplate
    }

    public var id: String {
        "\(operation.rawValue)-\(promptTemplate.hashValue)"
    }
}
