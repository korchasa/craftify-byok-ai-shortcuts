import Foundation

public struct SummarizeOperation: OperationType {
    public let identifier = OperationKind.summarize.rawValue
    public let colorHex: String = ""

    public init() {}

    public func isValid(input _: OperationInput) -> Bool {
        // sentenceCountRange всегда валиден
        true
    }

    public func makeInventoryOperation(input: OperationInput, colorHex: String) -> InventoryOperation? {
        let params = SummarizeParams(sentenceCountRange: input.sentenceCountRange)
        guard let data = try? JSONEncoder().encode(params) else { return nil }
        let prompt = """
        I want you to act as an expert summarizer.

        <instructions>
        - Read user message
        - Summarize the text in exactly \(input.sentenceCountRange.min)-\(input.sentenceCountRange.max) sentences
        - Preserve the main ideas and key details
        - Return ONLY the summary text, without any additional formatting
        - Translate the summary to the English language
        </instructions>
        """
        return InventoryOperation(operation: .summarize, params: data, promptTemplate: prompt, colorHex: colorHex)
    }

    public func buildRequest(text _: String, operation _: InventoryOperation) -> URLRequest {
        URLRequest(url: URL(string: "")!)
    }

    public func parse(responseData: Data) throws -> String {
        guard let str = String(data: responseData, encoding: .utf8) else {
            throw NSError(domain: "SummarizeOperation", code: -1, userInfo: nil)
        }
        return str
    }
}
