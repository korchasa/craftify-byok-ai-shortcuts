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
    @Published public var selectedColorHex: String = AddOperationViewModel.palette.first!
    @Published public var sentenceCountRange: SentenceCountRange = .twoToThree
    @Published public var nativeLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"

    /// Проверяет, могут ли данные создать операцию
    public var isValid: Bool {
        guard let kind = selectedKind else { return false }
        let input = OperationInput(
            targetLanguage: targetLanguage,
            complexityLevel: complexityLevel,
            detailLevel: detailLevel,
            sentenceCountRange: sentenceCountRange,
            nativeLanguage: nativeLanguage
        )
        let operation = OperationFactory.make(kind: kind)
        return operation.isValid(input: input)
    }

    public init(nativeLanguage: String = Locale.current.language.languageCode?.identifier ?? "en") {
        self.selectedKind = OperationFactory.allKinds.first
        self.nativeLanguage = nativeLanguage
    }

    /// Создает InventoryOperation через соответствующую реализацию OperationType
    public func makeOperation() -> InventoryOperation? {
        guard let kind = selectedKind else { return nil }
        let input = OperationInput(
            targetLanguage: targetLanguage,
            complexityLevel: complexityLevel,
            detailLevel: detailLevel,
            sentenceCountRange: sentenceCountRange,
            nativeLanguage: nativeLanguage
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
        selectedColorHex = AddOperationViewModel.palette.first!
        sentenceCountRange = .twoToThree
    }

    deinit {}

    public static let palette: [String] = ColorPaletteConstants.palette

    /// Список поддерживаемых языков для перевода
    public var supportedLanguages: [SupportedLanguage] {
        SupportedLanguages.all
    }
}
