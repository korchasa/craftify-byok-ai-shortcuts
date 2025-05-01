import Common
import Foundation

public final class EditOperationViewModel: ObservableObject, Identifiable {
    public let id = UUID()
    @Published public var selectedKind: OperationKind?
    @Published public var targetLanguage: String = ""
    @Published public var complexityLevel: ComplexityLevel = .beginner
    @Published public var detailLevel: DetailLevel = .beginner
    @Published public var selectedColorHex: String

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
            self.complexityLevel = .beginner
            self.originalComplexityLevel = .beginner
            self.detailLevel = .beginner
            self.originalDetailLevel = .beginner
        case .simplify:
            let params = try? JSONDecoder().decode(SimplifyParams.self, from: operation.params)
            let level = params?.complexityLevel ?? .beginner
            self.complexityLevel = level
            self.originalComplexityLevel = level
            self.targetLanguage = ""
            self.originalTargetLanguage = ""
            self.detailLevel = .beginner
            self.originalDetailLevel = .beginner
        case .correct:
            self.targetLanguage = ""
            self.originalTargetLanguage = ""
            self.complexityLevel = .beginner
            self.originalComplexityLevel = .beginner
            self.detailLevel = .beginner
            self.originalDetailLevel = .beginner
        case .explain:
            let params = try? JSONDecoder().decode(ExplainParams.self, from: operation.params)
            let detail = params?.detailLevel ?? .beginner
            self.detailLevel = detail
            self.originalDetailLevel = detail
            self.targetLanguage = ""
            self.originalTargetLanguage = ""
            self.complexityLevel = .beginner
            self.originalComplexityLevel = .beginner
        }
    }

    public func makeOperation() -> InventoryOperation? {
        guard let kind = selectedKind else { return nil }
        let input = OperationInput(
            targetLanguage: targetLanguage,
            complexityLevel: complexityLevel,
            detailLevel: detailLevel
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
            detailLevel: detailLevel
        )
        let operation = OperationFactory.make(kind: kind)
        return operation.isValid(input: input)
    }
}
