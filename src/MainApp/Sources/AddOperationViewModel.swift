import Foundation

public final class AddOperationViewModel: ObservableObject {
    @Published public var selectedKind: OperationKind? {
        didSet { applyDefaults(for: selectedKind) }
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
    private let settings: AppSettingsManager

    public init(
        palette: [String] = LightMainAppColorPalette().palette(),
        settings: AppSettingsManager = .shared
    ) {
        self.palette = palette
        self.settings = settings
        self.selectedColorHex = palette.first!
        // Присваивание проходит через обёртку @Published, поэтому наблюдатель
        // didSet срабатывает и здесь — параметры типа по умолчанию выставляются
        self.selectedKind = OperationFactory.allKinds.first
    }

    /// Параметры, с которыми форма открывается для выбранного типа операции
    private func applyDefaults(for kind: OperationKind?) {
        guard let kind else { return }
        length = SummarizeLengths.defaultLength
        targetLanguage = kind == .translate ? defaultTargetLanguage : ""
    }

    /// Язык перевода по умолчанию — родной язык из настроек. Первый элемент
    /// общего списка для этого не годится: список отсортирован по коду ISO,
    /// и в начале стоит афарский, одинаково случайный для всех
    private var defaultTargetLanguage: String {
        let native = settings.nativeLanguage
        if supportedLanguages.contains(where: { $0.code == native }) {
            return native
        }
        return supportedLanguages.first?.code ?? ""
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
