import Foundation

public final class AddOperationViewModel: ObservableObject {
    @Published public var selectedKind: OperationKind? {
        didSet {
            guard let kind = selectedKind else { return }
            switch kind {
            case .translate:
                targetLanguage = supportedLanguages.first?.code ?? ""
                length = SummarizeLengths.defaultLength
            case .simplify:
                targetLanguage = ""
                length = SummarizeLengths.defaultLength
            case .correct:
                targetLanguage = ""
                length = SummarizeLengths.defaultLength
            case .explain:
                targetLanguage = ""
                length = SummarizeLengths.defaultLength
            case .summarize:
                targetLanguage = ""
                length = SummarizeLengths.defaultLength
            }
        }
    }

    @Published public var targetLanguage: String = ""
    @Published public var selectedColorHex: String
    @Published public var length: String = SummarizeLengths.defaultLength

    /// Проверяет, могут ли данные создать операцию
    public var isValid: Bool {
        guard let kind = selectedKind else { return false }
        let input = OperationInput(
            targetLanguage: targetLanguage,
            length: length
        )
        let operation = OperationFactory.make(kind: kind)
        return operation.isValid(input: input)
    }

    public let palette: [String]

    public init(palette: [String] = LightMainAppColorPalette().palette()) {
        self.selectedKind = OperationFactory.allKinds.first
        self.palette = palette
        self.selectedColorHex = palette.first!
    }

    /// Создает InventoryOperation через соответствующую реализацию OperationType
    public func makeOperation() -> InventoryOperation? {
        guard let kind = selectedKind else { return nil }
        let input = OperationInput(
            targetLanguage: targetLanguage,
            length: length
        )
        let operation = OperationFactory.make(kind: kind)
        return operation.makeInventoryOperation(input: input, colorHex: selectedColorHex)
    }

    /// Сбрасывает все поля в начальное состояние
    public func cancel() {
        selectedKind = nil
        targetLanguage = ""
        selectedColorHex = palette.first!
        length = SummarizeLengths.defaultLength
    }

    deinit {}

    /// Список поддерживаемых языков для перевода
    public var supportedLanguages: [SupportedLanguage] {
        SupportedLanguages.all
    }
}
