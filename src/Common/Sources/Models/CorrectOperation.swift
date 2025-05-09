import Foundation

public struct CorrectOperation: OperationType {
    public let identifier = OperationKind.correct.rawValue
    public let colorHex: String = ""
    private static let ERROR_CODE_URL_NOT_SUPPORTED = -100
    private static let ERROR_CODE_NO_TEXT = -101

    public init() {}

    public func isValid(input _: OperationInput) -> Bool {
        // Для коррекции нет специфических параметров, всегда валидно
        true
    }

    public func makeInventoryOperation(input _: OperationInput, colorHex: String) -> InventoryOperation? {
        let params = CorrectParams()
        guard let data = try? JSONEncoder().encode(params) else { return nil }
        return InventoryOperation(operation: .correct, params: data, colorHex: colorHex)
    }

    public func promptTemplate(for _: OperationInput) -> String {
        """
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
        Привит это саобщение с `markdown`, и <b>тегими</b>
        Your answer:
        Привет, это сообщение с `markdown` и <b>тегами</b>
        </examples>
        """
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

    public func resolveInput(input: OperationInput) throws -> String {
        if let text = input.text, !text.isEmpty {
            return text
        }
        if let url = input.url, !url.isEmpty {
            throw NSError(domain: "CorrectOperation", code: Self.ERROR_CODE_URL_NOT_SUPPORTED, userInfo: [NSLocalizedDescriptionKey: "URL input is not supported for CorrectOperation"])
        }
        throw NSError(domain: "CorrectOperation", code: Self.ERROR_CODE_NO_TEXT, userInfo: [NSLocalizedDescriptionKey: "No text provided"])
    }

    public func decodeInput(from data: Data) throws -> OperationInput {
        _ = try JSONDecoder().decode(CorrectParams.self, from: data)
        return OperationInput()
    }
}
