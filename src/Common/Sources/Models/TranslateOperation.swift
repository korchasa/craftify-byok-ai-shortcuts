import Foundation

public struct TranslateOperation: OperationType {
    public let identifier = OperationKind.translate.rawValue
    public let colorHex: String = ""
    private static let ERROR_CODE_URL_NOT_SUPPORTED = -100
    private static let ERROR_CODE_NO_TEXT = -101

    public init() {}

    public func isValid(input: OperationInput) -> Bool {
        !input.targetLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func makeInventoryOperation(input: OperationInput, colorHex: String) -> InventoryOperation? {
        let params = TranslateParams(targetLanguage: input.targetLanguage)
        guard let data = try? JSONEncoder().encode(params) else { return nil }
        return InventoryOperation(operation: .translate, params: data, colorHex: colorHex)
    }

    public func promptTemplate(for _: OperationInput) -> String {
        // Вернуть шаблон промпта для translate
        "..."
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

    public func resolveInput(input: OperationInput) throws -> String {
        if let text = input.text, !text.isEmpty {
            return text
        }
        if let url = input.url, !url.isEmpty {
            throw NSError(domain: "TranslateOperation", code: Self.ERROR_CODE_URL_NOT_SUPPORTED, userInfo: [NSLocalizedDescriptionKey: "URL input is not supported for TranslateOperation"])
        }
        throw NSError(domain: "TranslateOperation", code: Self.ERROR_CODE_NO_TEXT, userInfo: [NSLocalizedDescriptionKey: "No text provided"])
    }

    public func decodeInput(from data: Data) throws -> OperationInput {
        let params = try JSONDecoder().decode(TranslateParams.self, from: data)
        return OperationInput(targetLanguage: params.targetLanguage)
    }
}
