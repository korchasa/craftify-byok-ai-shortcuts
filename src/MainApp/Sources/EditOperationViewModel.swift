import Foundation

public final class EditOperationViewModel: ObservableObject, Identifiable {
    public let id = UUID()
    @Published public var selectedKind: OperationKind? {
        didSet {
            guard let kind = selectedKind else { return }
            switch kind {
            case .translate:
                targetLanguage = supportedLanguages.first?.code ?? ""
            case .simplify:
                targetLanguage = ""
            case .correct:
                targetLanguage = ""
            case .explain:
                targetLanguage = ""
            case .summarize:
                targetLanguage = ""
            }
        }
    }

    @Published public var targetLanguage: String = ""
    @Published public var selectedColorHex: String
    @Published public var length: String = "2-3 sentences"

    public let originalOperation: InventoryOperation
    private let originalTargetLanguage: String
    private let originalKind: OperationKind
    private let originalColorHex: String
    public let palette: [String]

    /// Инициализирует ViewModel для редактирования операции
    /// - Parameters:
    ///   - operation: Операция для редактирования
    ///   - palette: Палитра цветов
    public init(operation: InventoryOperation, palette: [String] = LightMainAppColorPalette().palette()) {
        self.originalOperation = operation
        self.selectedKind = operation.operation
        self.selectedColorHex = operation.colorHex
        self.originalColorHex = operation.colorHex
        self.originalKind = operation.operation
        self.palette = palette
        // Десериализация параметров
        switch operation.operation {
        case .translate:
            let params = try? JSONDecoder().decode(TranslateParams.self, from: operation.params)
            let lang = params?.targetLanguage ?? ""
            self.targetLanguage = lang
            self.originalTargetLanguage = lang
        case .simplify:
            self.targetLanguage = ""
            self.originalTargetLanguage = ""
        case .correct:
            self.targetLanguage = ""
            self.originalTargetLanguage = ""
        case .explain:
            self.targetLanguage = ""
            self.originalTargetLanguage = ""
        case .summarize:
            let params = try? JSONDecoder().decode(SummarizeParams.self, from: operation.params)
            self.length = params?.length ?? "2-3 sentences"
            self.targetLanguage = ""
            self.originalTargetLanguage = ""
        }
    }

    /// Создаёт новую InventoryOperation на основе текущего состояния ViewModel
    /// - Returns: InventoryOperation или nil, если данные невалидны
    public func makeOperation() -> InventoryOperation? {
        guard let kind = selectedKind else { return nil }
        let input = OperationInput(
            targetLanguage: targetLanguage,
            length: length
        )
        let operation = OperationFactory.make(kind: kind)
        return operation.makeInventoryOperation(input: input, colorHex: selectedColorHex)
    }

    /// Сбрасывает все поля в исходное состояние
    public func cancel() {
        self.selectedKind = originalKind
        self.targetLanguage = originalTargetLanguage
        self.selectedColorHex = originalColorHex
        self.length = "2-3 sentences"
    }

    deinit {}

    /// Список поддерживаемых языков для перевода
    public var supportedLanguages: [SupportedLanguage] {
        SupportedLanguages.all
    }

    /// Проверяет валидность текущих данных для создания операции
    public var isValid: Bool {
        guard let kind = selectedKind else { return false }
        let input = OperationInput(
            targetLanguage: targetLanguage,
            length: length
        )
        let operation = OperationFactory.make(kind: kind)
        return operation.isValid(input: input)
    }
}
