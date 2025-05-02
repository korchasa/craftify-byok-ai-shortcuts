import Foundation

public struct SimplifyOperation: OperationType {
    public let identifier = OperationKind.simplify.rawValue
    public let colorHex: String = ""

    public init() {}

    public func isValid(input _: OperationInput) -> Bool {
        // complexityLevel всегда валиден
        true
    }

    public func makeInventoryOperation(input: OperationInput, colorHex: String) -> InventoryOperation? {
        let params = SimplifyParams(complexityLevel: input.complexityLevel)
        guard let data = try? JSONEncoder().encode(params) else { return nil }
        let prompt = """
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
        return InventoryOperation(operation: .simplify, params: data, promptTemplate: prompt, colorHex: colorHex)
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
}
