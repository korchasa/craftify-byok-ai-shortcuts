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

    /// Creates full LLM chat messages based on operation parameters and user text.
    func makeMessages(input: OperationInput, text: String) -> [LLMMessage]

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
        throw UserFacingError(
            messageKey: .errorNoText,
            adviceKey: .adviceCheckConnection
        )
    }

    /// По умолчанию операция не поддерживает URL
    var supportsURL: Bool { false }

    /// Default async resolveInput implementation: supports optional URL fetching using `URLInputResolver`.
    /// Operations that set `supportsURL = true` automatically gain URL handling.
    /// - Parameter input: OperationInput containing either `text` or `url`.
    /// - Returns: Resolved plain text ready for the LLM.
    /// - Throws: `UserFacingError` for empty input or fetch/parse issues.
    func resolveInput(input: OperationInput) async throws -> String {
        // If we already have plain text – just use it.
        if let text = input.text, !text.isEmpty {
            return text
        }
        // Handle URL only if the operation opted-in.
        if supportsURL, let urlString = input.url, !urlString.isEmpty {
            return try await URLInputResolver.resolve(urlString: urlString, logManager: nil)
        }
        // Fallback – mimic previous behaviour.
        throw UserFacingError(
            messageKey: .errorNoText,
            adviceKey: .adviceCheckConnection
        )
    }
}
