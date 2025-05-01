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
        let prompt = "Simplify the following text for a \(input.complexityLevel.rawValue) reader: {text}"
        return InventoryOperation(operation: .simplify, params: data, promptTemplate: prompt, colorHex: colorHex)
    }

    public func buildRequest(text _: String, operation _: InventoryOperation) -> URLRequest {
        // TODO: delegate to LLMAPIClient
        URLRequest(url: URL(string: "")!)
    }

    public func parse(responseData: Data) throws -> String {
        guard let str = String(data: responseData, encoding: .utf8) else {
            throw NSError(domain: "SimplifyOperation", code: -1, userInfo: nil)
        }
        return str
    }
}
