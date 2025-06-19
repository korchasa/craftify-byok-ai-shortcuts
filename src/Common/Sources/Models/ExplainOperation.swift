import Foundation
import os

public struct ExplainOperation: OperationType {
    public let identifier = OperationKind.explain.rawValue
    public let colorHex: String = ""

    public init() {}

    public func isValid(input _: OperationInput) -> Bool {
        // detailLevel всегда валиден
        true
    }

    public func makeInventoryOperation(input: OperationInput, colorHex: String) -> InventoryOperation? {
        let params = ExplainParams(detailLevel: input.detailLevel)
        guard let data = try? JSONEncoder().encode(params) else { return nil }
        return InventoryOperation(operation: .explain, params: data, colorHex: colorHex)
    }

    /// Генерирует promptTemplate для данной операции с учётом текущего языка
    public func makeMessages(input: OperationInput, text: String) -> [LLMMessage] {
        let nativeLang = AppSettingsManager.shared.nativeLanguageEnglishName
        let systemContent = """
        # INSTRUCTIONS

        CURRENT USER LANGUAGE: \(nativeLang)

        Follow strictly in order:

        1. Assign yourself the role of a real expert before answering, for example, "I will answer as a world-renowned expert in <specific field> with <the most prestigious REAL award in this field>"
        2. Give a CONCRETE and USEFUL explanation of the provided text in simple language in few sentences
        3. Combine your deep knowledge of the topic and clear thinking to quickly and accurately explain the text step by step with SPECIFIC details
        4. Your answer is critically important for my understanding
        5. Adapt your answer to the specified level (teenager, expert, etc.)
        6. Write your answer in a natural, human language
        7. Respond in plain text format

        ## Examples

        ### Example 1:
        Request:
        - Target language: english
        - Level: adult
        - User request: The Dunning-Kruger effect

        Response:
        The Dunning-Kruger effect — the lower the competence, the higher the confidence (and vice versa).

        Overestimation at a low level: little experience → no skills to see mistakes → inflated self-esteem.

        Underestimation at a high level: experts know the difficulties → see themselves as "ordinary" .

        Awareness gap: discrepancy between real and perceived abilities.

        How to avoid: seek external feedback and constantly learn to better understand your own limits.

        ### Example 2:

        Request:
        - Target language: українська
        - Level: школяр
        - User request: Ефект Даннінґа-Крюґера

        Response:
        Ефект Даннінґа-Крюґера — це правило: чим менше ти знаєш, тим упевненіше себе почуваєш, і навпаки.
            •	Переоцінка на початку: мало досвіду → не бачиш своїх помилок → здається, що ти геній.
            •	Недооцінка у майстрів: справжні знавці бачать усі труднощі → вважають себе «звичайними».

        «Ямка незнання»: різниця між тим, що ти справді вмієш, і тим, що про себе думаєш.

        Як не потрапити у пастку: проси чесний відгук у інших і постійно вчися — так краще розумітимеш свої межі.
        """
        let system = LLMMessage(role: .system, content: systemContent)
        let user = LLMMessage(role: .user, content: """
        - Target language: \(nativeLang)
        - Level: \(input.detailLevel.rawValue)
        - User request: \(text)
        """)
        return [system, user]
    }

    public func buildRequest(text _: String, operation _: InventoryOperation) -> URLRequest {
        URLRequest(url: URL(string: "")!)
    }

    public func parse(responseData: Data) throws -> String {
        guard let str = String(data: responseData, encoding: .utf8) else {
            throw UserFacingError(
                messageKey: .errorParsing,
                adviceKey: .adviceTryAgainLater
            )
        }
        return str
    }

    /// Режим обработки результата операции: отображать результат во всплывающем окне
    public var resultMode: ResultMode { .display }

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

    public func decodeInput(from data: Data) throws -> OperationInput {
        let params = try JSONDecoder().decode(ExplainParams.self, from: data)
        return OperationInput(detailLevel: params.detailLevel)
    }
}
