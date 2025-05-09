import Foundation

public struct SimplifyOperation: OperationType {
    public let identifier = OperationKind.simplify.rawValue
    public let colorHex: String = ""
    private static let ERROR_CODE_URL_NOT_SUPPORTED = -100
    private static let ERROR_CODE_NO_TEXT = -101

    public init() {}

    public func isValid(input _: OperationInput) -> Bool {
        // complexityLevel всегда валиден
        true
    }

    public func makeInventoryOperation(input: OperationInput, colorHex: String) -> InventoryOperation? {
        let params = SimplifyParams(complexityLevel: input.complexityLevel)
        guard let data = try? JSONEncoder().encode(params) else { return nil }
        return InventoryOperation(operation: .simplify, params: data, colorHex: colorHex)
    }

    public func promptTemplate(for input: OperationInput) -> String {
        """
        I want you to act as an expert simplifier.

        <instructions>
        - Read user message
        - Simplify the text for a \(input.complexityLevel.rawValue) reader
        - Preserve the original meaning, but use simpler words and sentence structure
        - Keep all formatting (including markdown and HTML tags)
        - Return ONLY the simplified text without any additional formatting
        </instructions>

        <examples>
        User message:
        The mitochondria is the powerhouse of the cell.
        Your answer:
        Cells get their energy from mitochondria.

        User message:
        Митохондрии — это энергетические станции клетки.
        Your answer:
        Клетка получает энергию от митохондрий.
        </examples>
        """
    }

    public func buildRequest(text _: String, operation _: InventoryOperation) -> URLRequest {
        URLRequest(url: URL(string: "")!)
    }

    public func parse(responseData: Data) throws -> String {
        guard let str = String(data: responseData, encoding: .utf8) else {
            throw NSError(domain: "SimplifyOperation", code: -1, userInfo: nil)
        }
        return str
    }

    public func resolveInput(input: OperationInput) throws -> String {
        if let text = input.text, !text.isEmpty {
            return text
        }
        if let url = input.url, !url.isEmpty {
            throw NSError(domain: "SimplifyOperation", code: Self.ERROR_CODE_URL_NOT_SUPPORTED, userInfo: [NSLocalizedDescriptionKey: "URL input is not supported for SimplifyOperation"])
        }
        throw NSError(domain: "SimplifyOperation", code: Self.ERROR_CODE_NO_TEXT, userInfo: [NSLocalizedDescriptionKey: "No text provided"])
    }

    public func decodeInput(from data: Data) throws -> OperationInput {
        let params = try JSONDecoder().decode(SimplifyParams.self, from: data)
        return OperationInput(complexityLevel: params.complexityLevel)
    }
}
