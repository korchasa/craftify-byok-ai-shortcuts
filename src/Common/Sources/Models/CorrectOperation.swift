import Foundation

public struct CorrectOperation: OperationType {
    public let identifier = OperationKind.correct.rawValue
    public let colorHex: String = ""

    public init() {}

    public func isValid(input _: OperationInput) -> Bool {
        // Для коррекции нет специфических параметров, всегда валидно
        true
    }

    public func makeInventoryOperation(input _: OperationInput, colorHex: String) -> InventoryOperation? {
        let params = CorrectParams()
        guard let data = try? JSONEncoder().encode(params) else { return nil }
        let prompt = """
        I want you to act as an expert editor.

        <instructions>
        - Read user message
        - Correct any spelling, grammar, and punctuation errors.
        - Respect the original text language, structure, and formatting.
        - Return ONLY the corrected text without any additional formatting.
        </instructions>

        <examples>
        User message:
        Hi tis is a mesage with `markdown` and <b>tegs</b>
        Your answer:
        Hi, this is a message with `markdown` and <b>tags</b>

        User message:
        Привит это саобщение с \\`markdown\\`, и <b>тегими</b>
        Your answer:
        Привет, это сообщение с \\`markdown\\` и <b>тегами</b>
        </examples>
        """

        return InventoryOperation(operation: .correct, params: data, promptTemplate: prompt, colorHex: colorHex)
    }

    public func buildRequest(text _: String, operation _: InventoryOperation) -> URLRequest {
        URLRequest(url: URL(string: "")!)
    }

    public func parse(responseData: Data) throws -> String {
        guard let str = String(data: responseData, encoding: .utf8) else {
            throw NSError(domain: "CorrectOperation", code: -1, userInfo: nil)
        }
        return str
    }
}
