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

    /// Режим обработки результата операции: копировать в буфер обмена или отображать во всплывающем окне
    var resultMode: ResultMode { get }
}

/// Дефолтная реализация resultMode: результат копируется в буфер обмена
public extension OperationType {
    /// Режим обработки результата по умолчанию: копировать в буфер обмена
    var resultMode: ResultMode { .clipboard }
}
