import Foundation

/// Операция инвентаря Craftify (тип, параметры, шаблон промпта)
public struct InventoryOperation: Codable, Equatable, Hashable, Identifiable {
    /// Тип операции (translate, simplify, correct, explain)
    public let operation: OperationKind
    /// Сериализованные параметры операции
    public let params: Data // Encoded params (type depends on operation)
    /// Цвет операции (hex, например, "3288bd")
    public let colorHex: String

    public func hash(into hasher: inout Hasher) {
        hasher.combine(operation)
        hasher.combine(params.hashValue)
        hasher.combine(colorHex)
    }

    /// Инициализация InventoryOperation
    /// - Parameters:
    ///   - operation: Тип операции
    ///   - params: Сериализованные параметры
    ///   - colorHex: Цвет операции (hex)
    public init(operation: OperationKind, params: Data, colorHex: String = "3288bd") {
        self.operation = operation
        self.params = params
        self.colorHex = colorHex
    }

    public var id: String {
        "\(operation.rawValue)-\(params.hashValue)-\(colorHex)"
    }
}
