import Foundation

/// Операция перевода текста для Craftify.
public struct TranslateOperation: OperationType {
    /// Уникальный идентификатор операции ("translate").
    public let identifier = OperationKind.translate.rawValue
    /// Цвет операции (по умолчанию пустая строка).
    public let colorHex: String = ""

    /// Инициализация TranslateOperation.
    public init() {}

    /// Проверяет, что целевой язык не пустой.
    /// - Parameter input: Входные параметры операции.
    /// - Returns: true, если целевой язык задан.
    public func isValid(input: OperationInput) -> Bool {
        !input.targetLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Создаёт InventoryOperation для перевода.
    /// - Parameters:
    ///   - input: Входные параметры.
    ///   - colorHex: Цвет операции.
    /// - Returns: InventoryOperation или nil при ошибке сериализации.
    public func makeInventoryOperation(input: OperationInput, colorHex: String) -> InventoryOperation? {
        let params = TranslateParams(targetLanguage: input.targetLanguage)
        guard let data = try? JSONEncoder().encode(params) else { return nil }
        return InventoryOperation(operation: .translate, params: data, colorHex: colorHex)
    }

    /// Итоговый системный промпт перевода с подставленным целевым языком.
    public func defaultSystemPrompt(input: OperationInput) -> String {
        let englishName = SupportedLanguages.all.first(where: { $0.code == input.targetLanguage })?.englishName ?? input.targetLanguage
        return """
        I want you to act as an expert translator.

        <instructions>
        - Read user message
        - Translate the text to the \(englishName) language
        - Preserve the original meaning, tone, and formatting (including markdown and HTML tags).
        - Return ONLY the translated text without any additional formatting.
        </instructions>
        """
    }

    /// User-сообщение перевода: сам текст без обвязки.
    public func userContent(input _: OperationInput, text: String) -> String {
        text
    }

    /// Формирует URLRequest для отправки к LLM (stub).
    public func buildRequest(text _: String, operation _: InventoryOperation) -> URLRequest {
        // Stub: actual request built by LLMAPIClient
        URLRequest(url: URL(string: "")!)
    }

    /// Парсит ответ от LLM.
    /// - Parameter responseData: Данные ответа.
    /// - Throws: UserFacingError при ошибке декодирования.
    /// - Returns: Строка результата.
    public func parse(responseData: Data) throws -> String {
        guard let str = String(data: responseData, encoding: .utf8) else {
            throw UserFacingError(
                messageKey: .errorParsing,
                adviceKey: .adviceTryAgainLater
            )
        }
        return str
    }

    /// Разрешает входные данные для перевода.
    /// - Parameter input: Входные параметры.
    /// - Throws: UserFacingError, если нет текста или передан url.
    /// - Returns: Текст для перевода.
    public func resolveInput(input: OperationInput) throws -> String {
        if let text = input.text, !text.isEmpty {
            return text
        }
        if let url = input.url, !url.isEmpty {
            throw UserFacingError(
                messageKey: .errorUrlNotSupported,
                adviceKey: .adviceCheckConnection
            )
        }
        throw UserFacingError(
            messageKey: .errorNoText,
            adviceKey: .adviceCheckConnection
        )
    }

    /// Декодирует OperationInput из сериализованных параметров.
    /// - Parameter data: Сериализованные параметры.
    /// - Throws: Ошибка декодирования.
    /// - Returns: OperationInput с целевым языком.
    public func decodeInput(from data: Data) throws -> OperationInput {
        let params = try JSONDecoder().decode(TranslateParams.self, from: data)
        return OperationInput(targetLanguage: params.targetLanguage)
    }

    /// Операция перевода не поддерживает обработку URL.
    public var supportsURL: Bool {
        false
    }
}
