import Foundation

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
        let prompt = "Explain the following concept at \(input.detailLevel.rawValue) level: {text}"
        return InventoryOperation(operation: .explain, params: data, promptTemplate: prompt, colorHex: colorHex)
    }

    public func buildRequest(text _: String, operation _: InventoryOperation) -> URLRequest {
        URLRequest(url: URL(string: "")!)
    }

    public func parse(responseData: Data) throws -> String {
        guard let str = String(data: responseData, encoding: .utf8) else {
            throw NSError(domain: "ExplainOperation", code: -1, userInfo: nil)
        }
        return str
    }
}
