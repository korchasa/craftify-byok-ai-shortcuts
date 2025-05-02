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

    /// Асинхронно получает текст для отправки в LLM: по умолчанию только text, url не поддерживается
    /// - Parameter input: OperationInput с текстом или url
    /// - Returns: Готовый текст для LLM
    /// - Throws: Ошибка, если нет текста или url не поддерживается
    func resolveInput(input: OperationInput) async throws -> String
}

/// Дефолтная реализация resultMode: результат копируется в буфер обмена
///
/// - Note: resolveInput по умолчанию поддерживает только text, url не поддерживается.
public extension OperationType {
    /// Режим обработки результата по умолчанию: копировать в буфер обмена
    var resultMode: ResultMode { .clipboard }

    /// Асинхронно получает текст для отправки в LLM: по умолчанию только text, url не поддерживается
    /// - Parameter input: OperationInput с текстом или url
    /// - Returns: Готовый текст для LLM
    /// - Throws: Ошибка, если нет текста или url не поддерживается
    func resolveInput(input: OperationInput) throws -> String {
        if let text = input.text, !text.isEmpty {
            return text
        }
        throw NSError(domain: "OperationType", code: -100, userInfo: [NSLocalizedDescriptionKey: "No text provided or URL not supported for this operation"])
    }
}
