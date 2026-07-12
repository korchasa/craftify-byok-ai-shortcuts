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

    public func makeInventoryOperation(input _: OperationInput, colorHex: String) -> InventoryOperation? {
        // ExplainOperation не требует параметров
        InventoryOperation(operation: .explain, params: Data(), colorHex: colorHex)
    }

    /// Генерирует promptTemplate для данной операции с учётом текущего языка
    public func makeMessages(input _: OperationInput, text: String) -> [LLMMessage] {
        let nativeLang = AppSettingsManager.shared.nativeLanguageEnglishName
        let systemContent = """
        # INSTRUCTIONS

        Follow strictly in order:

        1. Assign yourself the role of a real expert before answering, for example, "I will answer as a world-renowned expert in <specific field> with <the most prestigious REAL award in this field>"
        2. Combine your deep knowledge of the topic and clear thinking to quickly and accurately explain the text step by step with SPECIFIC details
        3. Your answer is critically important for my understanding
        4. Write "TL;DR" section in 1-2 sentences, the essence of the text
        5. Write detailed explanation in a natural, human language in ##Response structure##

        ## Response structure
        <I will answer as a world-renowned expert in %REAL specific field% with %the most prestigious REAL award%>

        TL;DR: <1-2 sentences, the essence of the text>

        <Detailed explanation of the text with analysis by meaning, key ideas, and context. Include interpretation of complex terms or concepts.>

        ## Examples

        ### Example 1:
        Request:
        - Target language: english
        - User request: Nocebo

        Response:
        <I will answer as a world-renowned expert in clinical psychology with the Lasker Award for Medical Research>

        TL;DR: Nocebo is an effect where a patient's negative expectations cause a worsening of condition or side effects, even if the treatment contains no harmful substances.

        Detailed explanation: "Nocebo" means "I will harm" in Latin and is the opposite of the placebo effect, where positive expectations improve health. If a patient expects bad effects from treatment, these expectations can cause real symptoms.

        For example, warnings about side effects may lead a person to feel them even if the medicine is inactive. This happens because stress and anxiety affect the body, increasing pain and fatigue.

        Doctors should consider the nocebo effect to better inform patients and foster a positive mindset, reducing negative reactions and improving treatment. In short, our thoughts and expectations truly affect health.

        ### Example 2:

        Request:
        - Target language: українська
        - User request: Ефект Даннінґа-Крюґера

        Response:
        <Я відповім як всесвітньо визнаний експерт у галузі когнітивної психології, володар премії APA за видатний науковий внесок на ранньому етапі кар'єри в психології>

        TL;DR: Ефект Даннінга-Крюгера — це когнітивне спотворення, при якому люди з низьким рівнем знань або навичок у якійсь сфері переоцінюють свої здібності, не усвідомлюючи власних помилок.

        Детальне пояснення: Ефект Даннінга-Крюгера, описаний психологами Девідом Даннінгом і Джастіном Крюгером у 1999 році, полягає в тому, що люди з низькою компетентністю у певній сфері часто не можуть об'єктивно оцінити свої знання через відсутність метапізнання — здатності усвідомлювати свої помилки.

        Наприклад, новачок у шахах може вважати себе вправним, не розуміючи своїх помилок, тоді як досвідчений гравець краще оцінює свої слабкі сторони.

        Цей ефект важливий для розуміння поведінки, навчання, прийняття рішень і самооцінки, пояснюючи, чому люди іноді вперто тримаються за неправильні переконання і не прагнуть до розвитку.

        Усвідомлення власних обмежень є ключем до зростання, а його відсутність веде до переоцінки себе і помилок.
        """
        let system = LLMMessage(role: .system, content: systemContent)
        let user = LLMMessage(role: .user, content: """
        - Target language: \(nativeLang)
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
    public var resultMode: ResultMode {
        .display
    }

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

    public func decodeInput(from _: Data) -> OperationInput {
        OperationInput()
    }
}
