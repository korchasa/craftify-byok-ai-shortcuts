import Common
import Foundation

public final class AddOperationViewModel: ObservableObject {
    public static let minStylePreservationLevel = 1
    public static let maxStylePreservationLevel = 3

    @Published public var selectedType: OperationType?
    @Published public var targetLanguage: String = ""
    @Published public var complexityLevel: ComplexityLevel = .beginner
    @Published public var stylePreservationLevel: Int = minStylePreservationLevel
    @Published public var detailLevel: DetailLevel = .beginner

    public var isValid: Bool {
        switch selectedType {
        case .translate:
            !targetLanguage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .simplify:
            true // complexityLevel всегда валиден
        case .correct:
            (Self.minStylePreservationLevel ... Self.maxStylePreservationLevel).contains(stylePreservationLevel)
        case .explain:
            true // detailLevel всегда валиден
        case .none:
            false
        }
    }

    public init() {}

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
        selectedType = nil
        targetLanguage = ""
        complexityLevel = .beginner
        stylePreservationLevel = Self.minStylePreservationLevel
        detailLevel = .beginner
    }

    deinit {}
}
