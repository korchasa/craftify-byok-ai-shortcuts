import Foundation

/// Операция инвентаря Craftify (тип, параметры, шаблон промпта)
public struct InventoryOperation: Codable, Equatable, Hashable {
    /// Тип операции (translate, simplify, correct, explain)
    public let operation: OperationType
    /// Сериализованные параметры операции
    public let params: Data // Encoded params (type depends on operation)
    /// Шаблон промпта для LLM
    public let promptTemplate: String
    /// Цвет операции (hex, например, "3288bd")
    public let colorHex: String

    public func hash(into hasher: inout Hasher) {
        hasher.combine(operation)
        hasher.combine(params.hashValue)
        hasher.combine(promptTemplate)
        hasher.combine(colorHex)
    }

    /// Инициализация InventoryOperation
    /// - Parameters:
    ///   - operation: Тип операции
    ///   - params: Сериализованные параметры
    ///   - promptTemplate: Шаблон промпта
    ///   - colorHex: Цвет операции (hex)
    public init(operation: OperationType, params: Data, promptTemplate: String, colorHex: String = "3288bd") {
        self.operation = operation
        self.params = params
        self.promptTemplate = promptTemplate
        self.colorHex = colorHex
    }

    public var id: String {
        "\(operation.rawValue)-\(promptTemplate.hashValue)-\(colorHex)"
    }
}
