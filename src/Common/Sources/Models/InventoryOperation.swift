import Foundation

/// Операция инвентаря Craftify (тип, параметры, шаблон промпта)
public struct InventoryOperation: Codable, Equatable, Hashable, Identifiable {
    /// Тип операции (translate, simplify, correct, explain)
    public let operation: OperationKind
    /// Сериализованные параметры операции
    public let params: Data // Encoded params (type depends on operation)
    /// Цвет операции (hex, например, "3288bd")
    public let colorHex: String
    /// Отредактированный пользователем системный промпт; nil — используется
    /// дефолтный текст, собранный из шаблона операции (старые записи без
    /// этого поля декодируются как nil)
    public let customPrompt: String?

    public func hash(into hasher: inout Hasher) {
        hasher.combine(operation)
        hasher.combine(params.hashValue)
        hasher.combine(colorHex)
        hasher.combine(customPrompt)
    }

    /// Инициализация InventoryOperation
    /// - Parameters:
    ///   - operation: Тип операции
    ///   - params: Сериализованные параметры
    ///   - colorHex: Цвет операции (hex)
    ///   - customPrompt: Пользовательский системный промпт (nil — из шаблона)
    public init(operation: OperationKind, params: Data, colorHex: String = "3288bd", customPrompt: String? = nil) {
        self.operation = operation
        self.params = params
        self.colorHex = colorHex
        self.customPrompt = customPrompt
    }

    /// Копия операции с другим пользовательским промптом
    public func with(customPrompt: String?) -> InventoryOperation {
        InventoryOperation(operation: operation, params: params, colorHex: colorHex, customPrompt: customPrompt)
    }

    public var id: String {
        "\(operation.rawValue)-\(params.hashValue)-\(colorHex)"
    }
}
