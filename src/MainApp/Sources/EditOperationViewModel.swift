import Common
import Foundation

public final class EditOperationViewModel: ObservableObject, Identifiable {
    public let id = UUID()
    @Published public var selectedKind: OperationKind?
    @Published public var targetLanguage: String = ""
    @Published public var complexityLevel: ComplexityLevel = .schoolchild
    @Published public var detailLevel: DetailLevel = .schoolchild
    @Published public var selectedColorHex: String
    @Published public var sentenceCountRange: SentenceCountRange = .twoToThree

    private let originalOperation: InventoryOperation
    private let originalTargetLanguage: String
    private let originalComplexityLevel: ComplexityLevel
    private let originalDetailLevel: DetailLevel
    private let originalColorHex: String
    private let originalKind: OperationKind

    public init(operation: InventoryOperation) {
        self.originalOperation = operation
        self.selectedKind = operation.operation
        self.selectedColorHex = operation.colorHex
        self.originalColorHex = operation.colorHex
        self.originalKind = operation.operation
        // Десериализация параметров
        switch operation.operation {
        case .translate:
            let params = try? JSONDecoder().decode(TranslateParams.self, from: operation.params)
            let lang = params?.targetLanguage ?? ""
            self.targetLanguage = lang
            self.originalTargetLanguage = lang
            self.complexityLevel = .schoolchild
            self.originalComplexityLevel = .schoolchild
            self.detailLevel = .schoolchild
            self.originalDetailLevel = .schoolchild
        case .simplify:
            let params = try? JSONDecoder().decode(SimplifyParams.self, from: operation.params)
            let level = params?.complexityLevel ?? .schoolchild
            self.complexityLevel = level
            self.originalComplexityLevel = level
            self.targetLanguage = ""
            self.originalTargetLanguage = ""
            self.detailLevel = .schoolchild
            self.originalDetailLevel = .schoolchild
        case .correct:
            self.targetLanguage = ""
            self.originalTargetLanguage = ""
            self.complexityLevel = .schoolchild
            self.originalComplexityLevel = .schoolchild
            self.detailLevel = .schoolchild
            self.originalDetailLevel = .schoolchild
        case .explain:
            let params = try? JSONDecoder().decode(ExplainParams.self, from: operation.params)
            let detail = params?.detailLevel ?? .schoolchild
            self.detailLevel = detail
            self.originalDetailLevel = detail
            self.targetLanguage = ""
            self.originalTargetLanguage = ""
            self.complexityLevel = .schoolchild
            self.originalComplexityLevel = .schoolchild
        case .summarize:
            let params = try? JSONDecoder().decode(SummarizeParams.self, from: operation.params)
            let range = params?.sentenceCountRange ?? .twoToThree
            self.sentenceCountRange = range
            self.targetLanguage = ""
            self.originalTargetLanguage = ""
            self.complexityLevel = .schoolchild
            self.originalComplexityLevel = .schoolchild
            self.detailLevel = .schoolchild
            self.originalDetailLevel = .schoolchild
        }
    }

    public func makeOperation() -> InventoryOperation? {
        guard let kind = selectedKind else { return nil }
        let input = OperationInput(
            targetLanguage: targetLanguage,
            complexityLevel: complexityLevel,
            detailLevel: detailLevel,
            sentenceCountRange: sentenceCountRange
        )
        let operation = OperationFactory.make(kind: kind)
        return operation.makeInventoryOperation(input: input, colorHex: selectedColorHex)
    }

    public func cancel() {
        self.selectedKind = originalKind
        self.targetLanguage = originalTargetLanguage
        self.complexityLevel = originalComplexityLevel
        self.detailLevel = originalDetailLevel
        self.selectedColorHex = originalColorHex
        self.sentenceCountRange = .twoToThree
    }

    deinit {}

    public static let palette: [String] = [
        "9e0142", "d53e4f", "f46d43", "fdae61", "fee08b", "e6f598", "abdda4", "66c2a5", "3288bd", "5e4fa2"
    ]

    public var isValid: Bool {
        guard let kind = selectedKind else { return false }
        let input = OperationInput(
            targetLanguage: targetLanguage,
            complexityLevel: complexityLevel,
            detailLevel: detailLevel,
            sentenceCountRange: sentenceCountRange
        )
        let operation = OperationFactory.make(kind: kind)
        return operation.isValid(input: input)
    }
}
