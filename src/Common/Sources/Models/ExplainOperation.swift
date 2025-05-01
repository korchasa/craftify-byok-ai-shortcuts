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
        let prompt = """
        I want you to act as an expert explainer.

        <instructions>
        - Read user message
        - Explain the concept at the \(input.detailLevel.rawValue) level
        - Use clear, accessible language and examples appropriate for the audience
        - Respond in the language of the user message
        - Preserve all formatting (including markdown and HTML tags)
        - Return ONLY the explanation without any additional formatting
        </instructions>

        <examples>
        User message:
        What is mitochondria?
        Your answer for adult level:
        Mitochondria are membrane-bound cell organelles (mitochondrion, singular) that generate most of the chemical energy needed to power the cell's biochemical reactions. Chemical energy produced by the mitochondria is stored in a small molecule called adenosine triphosphate (ATP). Mitochondria contain their own small chromosomes. Generally, mitochondria, and therefore mitochondrial DNA, are inherited only from the mother.

        User message:
        Что такое гравитация?
        Your answer for child level:
        Гравитация — это сила, которая притягивает предметы друг к другу. Например, она удерживает нас на земле.
        </examples>
        """
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
