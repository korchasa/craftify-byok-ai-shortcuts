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
            // Смена типа операции обнуляет пользовательскую правку промпта:
            // текст другого типа не имеет смысла для нового
            if oldValue != selectedKind {
                promptText = currentDefaultPrompt
            }
        }
    }

    @Published public var targetLanguage: String = "" {
        didSet {
            guard oldValue != targetLanguage else { return }
            refreshPromptAfterParamsChange(previousDefault: defaultPrompt(targetLanguage: oldValue, length: length))
        }
    }

    @Published public var selectedColorHex: String
    @Published public var length: String = SummarizeLengths.defaultLength {
        didSet {
            guard oldValue != length else { return }
            refreshPromptAfterParamsChange(previousDefault: defaultPrompt(targetLanguage: targetLanguage, length: oldValue))
        }
    }

    /// Итоговый текст системного промпта, показанный на экране (редактируемый)
    @Published public var promptText: String = ""

    public let originalOperation: InventoryOperation
    private let originalTargetLanguage: String
    private let originalLength: String
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
            self.originalLength = SummarizeLengths.defaultLength
        case .simplify:
            self.targetLanguage = ""
            self.originalTargetLanguage = ""
            self.originalLength = SummarizeLengths.defaultLength
        case .correct:
            self.targetLanguage = ""
            self.originalTargetLanguage = ""
            self.originalLength = SummarizeLengths.defaultLength
        case .explain:
            self.targetLanguage = ""
            self.originalTargetLanguage = ""
            self.originalLength = SummarizeLengths.defaultLength
        case .summarize:
            let params = try? JSONDecoder().decode(SummarizeParams.self, from: operation.params)
            // Старые записи могли хранить локализованную строку пикера —
            // без нормализации выбор в пикере длины оставался пустым
            let storedLength = SummarizeLengths.normalize(params?.length ?? SummarizeLengths.defaultLength)
            self.length = storedLength
            self.originalLength = storedLength
            self.targetLanguage = ""
            self.originalTargetLanguage = ""
        }
        self.promptText = operation.customPrompt ?? currentDefaultPrompt
    }

    /// Дефолтный промпт для текущего типа и заданных параметров
    private func defaultPrompt(targetLanguage: String, length: String) -> String {
        guard let kind = selectedKind else { return "" }
        let input = OperationInput(targetLanguage: targetLanguage, length: length)
        return OperationFactory.make(kind: kind).defaultSystemPrompt(input: input)
    }

    /// Дефолтный промпт для текущего состояния полей
    public var currentDefaultPrompt: String {
        defaultPrompt(targetLanguage: targetLanguage, length: length)
    }

    /// Промпт совпадает с дефолтным (кнопке сброса нечего делать)
    public var isPromptDefault: Bool {
        promptText.trimmingCharacters(in: .whitespacesAndNewlines) ==
            currentDefaultPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Сброс текста промпта на дефолтное значение из шаблона
    public func resetPrompt() {
        promptText = currentDefaultPrompt
    }

    /// После смены параметров дефолтный текст меняется; если пользователь промпт
    /// не правил (текст был равен старому дефолту) — показываем новый дефолт
    private func refreshPromptAfterParamsChange(previousDefault: String) {
        if promptText == previousDefault {
            promptText = currentDefaultPrompt
        }
    }

    /// Создаёт новую InventoryOperation на основе текущего состояния ViewModel.
    /// Промпт сохраняется как пользовательский, только если он отличается от
    /// дефолтного и непуст — иначе операция продолжает следовать шаблону.
    public func makeOperation() -> InventoryOperation? {
        guard let kind = selectedKind else { return nil }
        let input = OperationInput(
            targetLanguage: targetLanguage,
            length: length
        )
        let operation = OperationFactory.make(kind: kind)
        let trimmedPrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        let customPrompt = (isPromptDefault || trimmedPrompt.isEmpty) ? nil : promptText
        // Фабрика собирает новый объект со свежим UUID и нулевой ячейкой, поэтому
        // идентификатор и место исходной операции возвращаем на место: правка
        // настройки не подменяет плитку и не сдвигает её по сетке
        return operation.makeInventoryOperation(input: input, colorHex: selectedColorHex)?
            .with(customPrompt: customPrompt)
            .with(id: originalOperation.id)
            .with(slot: originalOperation.slot)
    }

    /// Сбрасывает все поля в исходное состояние
    public func cancel() {
        self.selectedKind = originalKind
        self.targetLanguage = originalTargetLanguage
        self.selectedColorHex = originalColorHex
        self.length = originalLength
        self.promptText = originalOperation.customPrompt ?? currentDefaultPrompt
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
