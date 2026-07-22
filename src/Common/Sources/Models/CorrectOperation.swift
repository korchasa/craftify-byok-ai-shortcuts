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
        // CorrectOperation не имеет параметров
        InventoryOperation(operation: .correct, params: Data(), colorHex: colorHex)
    }

    public func defaultSystemPrompt(input _: OperationInput) -> String {
        """
        You will act as an EXPERT editor.

        FOLLOW these INSTRUCTIONS carefully for translating the text:
        1. READ the provided text in the user's message.
        2. Fix the text if it is not correct.
        3. Write your answer

        ###EXAMPLE 1
        User message:
        Hi tis is a mesage with `markdown` and <b>tegs</b>
        Your answer:
        Hi, this is a message with `markdown` and <b>tags</b>

        ###EXAMPLE 2
        User message:
        Привит это саобщение с `markdown`, и <b>тегими</b>
        Your answer:
        Привет, это сообщение с `markdown` и <b>тегами</b>
        """
    }

    public func userContent(input _: OperationInput, text: String) -> String {
        text
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
