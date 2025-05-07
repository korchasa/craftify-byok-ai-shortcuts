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

    /// Генерирует promptTemplate для данной операции с учётом текущего языка
    func promptTemplate(for input: OperationInput) -> String

    /// Асинхронно получает текст для отправки в LLM: по умолчанию только text, url не поддерживается
    /// - Parameter input: OperationInput с текстом или url
    /// - Returns: Готовый текст для LLM
    /// - Throws: Ошибка, если нет текста или url не поддерживается
    func resolveInput(input: OperationInput) async throws -> String

    /// Синхронное разрешение входных данных (если не требуется асинхронность)
    func resolveInput(input: OperationInput) throws -> String

    /// Декодирует OperationInput из сериализованных параметров
    func decodeInput(from data: Data) throws -> OperationInput

    /// Поддерживает ли операция обработку URL (скачивание контента)
    var supportsURL: Bool { get }
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

    /// По умолчанию операция не поддерживает URL
    var supportsURL: Bool { false }
}
