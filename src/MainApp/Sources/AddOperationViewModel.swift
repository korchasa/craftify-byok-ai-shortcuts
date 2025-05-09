import Foundation

public final class AddOperationViewModel: ObservableObject {
    @Published public var selectedKind: OperationKind? {
        didSet {
            guard let kind = selectedKind else { return }
            switch kind {
            case .translate:
                targetLanguage = supportedLanguages.first?.code ?? ""
                complexityLevel = .schoolchild
                detailLevel = .schoolchild
                sentenceCountRange = .twoToThree
            case .simplify:
                targetLanguage = ""
                complexityLevel = .schoolchild
                detailLevel = .schoolchild
                sentenceCountRange = .twoToThree
            case .correct:
                targetLanguage = ""
                complexityLevel = .schoolchild
                detailLevel = .schoolchild
                sentenceCountRange = .twoToThree
            case .explain:
                targetLanguage = ""
                complexityLevel = .schoolchild
                detailLevel = .schoolchild
                sentenceCountRange = .twoToThree
            case .summarize:
                targetLanguage = ""
                complexityLevel = .schoolchild
                detailLevel = .schoolchild
                sentenceCountRange = .twoToThree
            }
        }
    }

    @Published public var targetLanguage: String = ""
    @Published public var complexityLevel: ComplexityLevel = .schoolchild
    @Published public var detailLevel: DetailLevel = .schoolchild
    @Published public var selectedColorHex: String
    @Published public var sentenceCountRange: SentenceCountRange = .twoToThree

    /// Проверяет, могут ли данные создать операцию
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
            complexityLevel: complexityLevel,
            detailLevel: detailLevel,
            sentenceCountRange: sentenceCountRange
        )
        let operation = OperationFactory.make(kind: kind)
        return operation.makeInventoryOperation(input: input, colorHex: selectedColorHex)
    }

    /// Сбрасывает все поля в начальное состояние
    public func cancel() {
        selectedKind = nil
        targetLanguage = ""
        complexityLevel = .schoolchild
        detailLevel = .schoolchild
        selectedColorHex = palette.first!
        sentenceCountRange = .twoToThree
    }

    deinit {}

    /// Список поддерживаемых языков для перевода
    public var supportedLanguages: [SupportedLanguage] {
        SupportedLanguages.all
    }
}
