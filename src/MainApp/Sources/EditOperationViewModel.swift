import CraftifyShared
import Foundation

public final class EditOperationViewModel: ObservableObject, Identifiable {
    public let id = UUID()
    @Published public var selectedType: OperationType?
    @Published public var targetLanguage: String = ""
    @Published public var complexityLevel: ComplexityLevel = .beginner
    @Published public var stylePreservationLevel: Int = EditOperationViewModel.minStylePreservationLevel
    @Published public var detailLevel: DetailLevel = .beginner

    private let originalOperation: InventoryOperation
    private let originalTargetLanguage: String
    private let originalComplexityLevel: ComplexityLevel
    private let originalStylePreservationLevel: Int
    private let originalDetailLevel: DetailLevel

    public static let minStylePreservationLevel = 1
    public static let maxStylePreservationLevel = 3

    public var isValid: Bool {
        switch selectedType {
        case .translate:
            !targetLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .simplify:
            true
        case .correct:
            (Self.minStylePreservationLevel ... Self.maxStylePreservationLevel).contains(stylePreservationLevel)
        case .explain:
            true
        case .none:
            false
        }
    }

    public init(operation: InventoryOperation) {
        self.originalOperation = operation
        self.selectedType = operation.operation
        switch operation.operation {
        case .translate:
            let params = try? JSONDecoder().decode(TranslateParams.self, from: operation.params)
            let lang = params?.targetLanguage ?? ""
            self.targetLanguage = lang
            self.originalTargetLanguage = lang
            self.complexityLevel = .beginner
            self.originalComplexityLevel = .beginner
            self.stylePreservationLevel = Self.minStylePreservationLevel
            self.originalStylePreservationLevel = Self.minStylePreservationLevel
            self.detailLevel = .beginner
            self.originalDetailLevel = .beginner
        case .simplify:
            let params = try? JSONDecoder().decode(SimplifyParams.self, from: operation.params)
            let level = params?.complexityLevel ?? .beginner
            self.complexityLevel = level
            self.originalComplexityLevel = level
            self.targetLanguage = ""
            self.originalTargetLanguage = ""
            self.stylePreservationLevel = Self.minStylePreservationLevel
            self.originalStylePreservationLevel = Self.minStylePreservationLevel
            self.detailLevel = .beginner
            self.originalDetailLevel = .beginner
        case .correct:
            let params = try? JSONDecoder().decode(CorrectParams.self, from: operation.params)
            let style = params?.stylePreservationLevel ?? Self.minStylePreservationLevel
            self.stylePreservationLevel = style
            self.originalStylePreservationLevel = style
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
            self.stylePreservationLevel = Self.minStylePreservationLevel
            self.originalStylePreservationLevel = Self.minStylePreservationLevel
        }
    }

    public func makeOperation() -> InventoryOperation? {
        guard let type = selectedType, isValid else { return nil }
        switch type {
        case .translate:
            let params = TranslateParams(targetLanguage: targetLanguage)
            guard let data = try? JSONEncoder().encode(params) else { return nil }
            return InventoryOperation(operation: .translate, params: data, promptTemplate: "Translate the following text to \(targetLanguage): {text}")
        case .simplify:
            let params = SimplifyParams(complexityLevel: complexityLevel)
            guard let data = try? JSONEncoder().encode(params) else { return nil }
            return InventoryOperation(operation: .simplify, params: data, promptTemplate: "Simplify the following text for a \(complexityLevel.rawValue) reader: {text}")
        case .correct:
            let params = CorrectParams(stylePreservationLevel: stylePreservationLevel)
            guard let data = try? JSONEncoder().encode(params) else { return nil }
            return InventoryOperation(operation: .correct, params: data, promptTemplate: "Correct grammar and spelling, preserve style level \(stylePreservationLevel): {text}")
        case .explain:
            let params = ExplainParams(detailLevel: detailLevel)
            guard let data = try? JSONEncoder().encode(params) else { return nil }
            return InventoryOperation(operation: .explain, params: data, promptTemplate: "Explain the following concept at \(detailLevel.rawValue) level: {text}")
        }
    }

    public func cancel() {
        self.selectedType = originalOperation.operation
        self.targetLanguage = originalTargetLanguage
        self.complexityLevel = originalComplexityLevel
        self.stylePreservationLevel = originalStylePreservationLevel
        self.detailLevel = originalDetailLevel
    }

    deinit {}
}
