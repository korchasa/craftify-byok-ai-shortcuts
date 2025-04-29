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
    @Published public var selectedColorHex: String = AddOperationViewModel.palette.first!

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
            return InventoryOperation(operation: .translate, params: data, promptTemplate: "Translate the following text to \(targetLanguage): {text}", colorHex: selectedColorHex)
        case .simplify:
            let params = SimplifyParams(complexityLevel: complexityLevel)
            guard let data = try? JSONEncoder().encode(params) else { return nil }
            return InventoryOperation(operation: .simplify, params: data, promptTemplate: "Simplify the following text for a \(complexityLevel.rawValue) reader: {text}", colorHex: selectedColorHex)
        case .correct:
            let params = CorrectParams(stylePreservationLevel: stylePreservationLevel)
            guard let data = try? JSONEncoder().encode(params) else { return nil }
            return InventoryOperation(operation: .correct, params: data, promptTemplate: "Correct grammar and spelling, preserve style level \(stylePreservationLevel): {text}", colorHex: selectedColorHex)
        case .explain:
            let params = ExplainParams(detailLevel: detailLevel)
            guard let data = try? JSONEncoder().encode(params) else { return nil }
            return InventoryOperation(operation: .explain, params: data, promptTemplate: "Explain the following concept at \(detailLevel.rawValue) level: {text}", colorHex: selectedColorHex)
        }
    }

    public func cancel() {
        selectedType = nil
        targetLanguage = ""
        complexityLevel = .beginner
        stylePreservationLevel = Self.minStylePreservationLevel
        detailLevel = .beginner
        selectedColorHex = AddOperationViewModel.palette.first!
    }

    deinit {}

    public static let palette: [String] = [
        "9e0142", "d53e4f", "f46d43", "fdae61", "fee08b", "e6f598", "abdda4", "66c2a5", "3288bd", "5e4fa2"
    ]
}
