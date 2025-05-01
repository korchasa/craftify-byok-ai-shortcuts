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
        let prompt = "Correct grammar and spelling in the following text: {text}"
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
