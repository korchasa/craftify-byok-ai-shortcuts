import Foundation

public struct TranslateOperation: OperationType {
    public let identifier = OperationKind.translate.rawValue
    public let colorHex: String = ""

    public init() {}

    public func isValid(input: OperationInput) -> Bool {
        !input.targetLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func makeInventoryOperation(input: OperationInput, colorHex: String) -> InventoryOperation? {
        guard isValid(input: input) else { return nil }
        let params = TranslateParams(targetLanguage: input.targetLanguage)
        guard let data = try? JSONEncoder().encode(params) else { return nil }
        let prompt = "Translate the following text to \(input.targetLanguage): {text}"
        return InventoryOperation(operation: .translate, params: data, promptTemplate: prompt, colorHex: colorHex)
    }

    public func buildRequest(text _: String, operation _: InventoryOperation) -> URLRequest {
        // Stub: actual request built by LLMAPIClient
        URLRequest(url: URL(string: "")!)
    }

    public func parse(responseData: Data) throws -> String {
        guard let str = String(data: responseData, encoding: .utf8) else {
            throw NSError(domain: "TranslateOperation", code: -1, userInfo: nil)
        }
        return str
    }
}
