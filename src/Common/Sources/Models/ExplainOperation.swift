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
    public func promptTemplate(for input: OperationInput) -> String {
        let nativeLanguage = AppSettingsManager.shared.nativeLanguage
        let englishName = SupportedLanguages.all.first(where: { $0.code == nativeLanguage })?.englishName ?? nativeLanguage
        let displayName = SupportedLanguages.all.first(where: { $0.code == nativeLanguage })?.name ?? nativeLanguage
        os_log("[ExplainOperation] Prompt language code: %{public}@", nativeLanguage)
        os_log("[ExplainOperation] Prompt language englishName: %{public}@", englishName)
        os_log("[ExplainOperation] Prompt language displayName: %{public}@", displayName)
        return """
        # INSTRUCTIONS

        You MUST ALWAYS:
        - Respond in \(englishName)
        - Explain the concept at the \(input.detailLevel.rawValue) level
        - I do not have the ability to fill templates. NEVER use placeholders or omit code
        - You will be PUNISHED for incorrect answers
        - NEVER MAKE THINGS UP
        - You MUST NOT ignore critical context
        - ALWAYS follow ###Response Rules###

        ## Response Rules

        Follow strictly in order:

        1. Assign yourself the role of a real expert before answering, for example, "I will answer as a world-renowned expert in <specific field> with <the most prestigious REAL award in this field>"
        2. Give a CONCRETE and USEFUL explanation of the provided text in simple \(englishName) language in few sentences
        3. Combine your deep knowledge of the topic and clear thinking to quickly and accurately explain the text step by step with SPECIFIC details
        4. Your answer is critically important for my understanding
        5. Respond in a natural, human language, in plain text format
        6. ALWAYS use ##Example answer## for the structure of the first message

        ## Example

        Target language: english
        Level: student
        User request: The Dunning-Kruger effect

        Response:
        I will answer as a world-renowned expert in psychology with the prestigious American Psychological Association Award for Research Excellence.

        The Dunning-Kruger effect — the lower the competence, the higher the confidence (and vice versa).

        Overestimation at a low level: little experience → no skills to see mistakes → inflated self-esteem.

        Underestimation at a high level: experts know the difficulties → see themselves as "ordinary" .

        Awareness gap: discrepancy between real and perceived abilities.

        How to avoid: seek external feedback and constantly learn to better understand your own limits.
        """
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
