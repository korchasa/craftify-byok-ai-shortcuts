import Common
import Foundation

public final class AddOperationViewModel: ObservableObject {
    @Published public var selectedKind: OperationKind?
    @Published public var targetLanguage: String = ""
    @Published public var complexityLevel: ComplexityLevel = .beginner
    @Published public var detailLevel: DetailLevel = .beginner
    @Published public var selectedColorHex: String = AddOperationViewModel.palette.first!

    /// Проверяет, могут ли данные создать операцию
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

    public init() {}

    /// Создает InventoryOperation через соответствующую реализацию OperationType
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

    /// Сбрасывает все поля в начальное состояние
    public func cancel() {
        selectedKind = nil
        targetLanguage = ""
        complexityLevel = .beginner
        detailLevel = .beginner
        selectedColorHex = AddOperationViewModel.palette.first!
    }

    deinit {}

    public static let palette: [String] = [
        "9e0142", "d53e4f", "f46d43", "fdae61", "fee08b", "e6f598", "abdda4", "66c2a5", "3288bd", "5e4fa2"
    ]
}
