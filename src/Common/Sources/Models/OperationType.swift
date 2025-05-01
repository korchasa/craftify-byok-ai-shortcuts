import Foundation

/// Абстракция для всех операций Craftify
public protocol OperationType {
    /// Уникальный идентификатор операции для сериализации
    var identifier: String { get }
    /// Цвет операции в hex
    var colorHex: String { get }

    /// Проверяет корректность входных данных для операции
    func isValid(input: OperationInput) -> Bool
    /// Создает модель InventoryOperation на основе входных данных и цвета
    func makeInventoryOperation(input: OperationInput, colorHex: String) -> InventoryOperation?
    /// Формирует URLRequest для отправки к LLM
    func buildRequest(text: String, operation: InventoryOperation) -> URLRequest
    /// Парсит ответ от LLM
    func parse(responseData: Data) throws -> String
}
