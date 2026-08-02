import Combine
import Foundation
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

@preconcurrency
@MainActor
public final class ShareExtensionViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published public var operations: [InventoryOperation] = []
    /// Текст (или ссылка), над которым работаем — показывается в шапке экрана выбора
    @Published public private(set) var inputText: String = ""
    @Published public var isProcessing: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var displayResult: String? = nil
    @Published public var shouldCloseExtension: Bool = false
    /// Текущая стадия обработки (nil вне обработки)
    @Published public private(set) var stage: ProcessingStage? = nil
    /// Ключ последней ошибки — определяет, доступен ли повтор
    @Published public private(set) var lastErrorKey: UserFacingErrorKey? = nil

    // MARK: - Properties

    public let manager: ShareExtensionManager
    private var currentResultMode: ResultMode = .clipboard
    public var processingTask: Task<Void, Never>?
    public var processingTimeoutSeconds: Double = 30
    public var logContentLength: Int = 100
    private var hasCompleted = false
    /// Последняя запущенная операция — цель для повтора после транзиентной ошибки
    private var lastOperation: InventoryOperation?

    /// Транзиентные ошибки, для которых имеет смысл кнопка «Повторить»
    private static let retryableErrorKeys: Set<UserFacingErrorKey> = [
        .errorNetwork,
        .errorRateLimited,
        .errorProcessing,
        .errorDownloadFailed,
        .errorParsing,
        .errorTimeout,
        .adviceUnknownError
    ]

    /// Доступен ли повтор для последней ошибки
    public var isLastErrorRetryable: Bool {
        guard let key = lastErrorKey else { return false }
        return Self.retryableErrorKeys.contains(key)
    }

    private var logManager: LogManagerShared {
        manager.logManager
    }

    // MARK: - Initialization

    public init(manager: ShareExtensionManager) {
        self.manager = manager
        let input = manager.inputText
        let inputPreview = String(input.prefix(100))

        // Добавляем дополнительное логирование для отладки
        manager.logManager.log(LogEntry(
            level: .debug,
            module: "ShareExtensionViewModel",
            message: "Initializing ShareExtensionViewModel, initial input: '\(inputPreview)'",
            metadata: ["input_length": String(input.count)],
            timestamp: Date()
        ))

        // Загружаем все операции по умолчанию, а затем отфильтруем их в updateInputText когда будет доступен контент
        self.operations = manager.inventoryManager.inventory
        manager.inputText = Self.truncated(input)
        self.inputText = manager.inputText
    }

    /// Вход — ссылка, а не выделенный текст: шапка подписывает его иначе
    public var isInputURL: Bool {
        OperationInput.isHttpURL(string: inputText)
    }

    // MARK: - Public Methods

    public func process(operation: InventoryOperation) {
        guard !isProcessing else { return }
        hasCompleted = false
        lastOperation = operation
        lastErrorKey = nil
        manager.resetCancellation()

        logProcessingStart()

        currentResultMode = OperationFactory.make(kind: operation.operation, logManager: self.logManager).resultMode
        displayResult = nil

        startProcessing(operation: operation)
    }

    public func updateInputText(_ text: String) {
        let truncatedText = Self.truncated(text)
        manager.inputText = truncatedText
        inputText = truncatedText

        logTextUpdate(truncatedText)
        updateOperationsForInput(truncatedText)
    }

    public func cancel() {
        processingTask?.cancel()
        manager.cancelProcessing()
        // Помечаем прогон завершённым, чтобы уже летящее завершение не изменило
        // состояние (errorMessage/displayResult) после отмены
        hasCompleted = true
        isProcessing = false
        setStage(nil)
    }

    /// Сбрасывает ошибку после закрытия алерта и возвращает пользователя к сетке операций.
    public func dismissError() {
        errorMessage = nil
        isProcessing = false
        setStage(nil)
    }

    /// Повторяет последнюю операцию после транзиентной ошибки (кнопка «Повторить» в алерте)
    public func retry() {
        guard isLastErrorRetryable, let operation = lastOperation else { return }
        errorMessage = nil
        setStage(nil)
        process(operation: operation)
    }

    /// Copies currently displayed result to clipboard and closes extension.
    public func copyDisplayedResultAndClose() {
        guard let text = displayResult, !text.isEmpty else { return }
        if manager.copyToClipboard(text) {
            notifySuccessAndClose()
        } else {
            errorMessage = L10n.errorClipboard
        }
    }

    // MARK: - Private Methods

    private func logProcessingStart() {
        let inputPreview = String(manager.inputText.prefix(self.logContentLength))
        let isURL = OperationInput.isHttpURL(string: manager.inputText)
        manager.logManager.log(LogEntry(
            level: .debug,
            module: "ShareExtensionViewModel",
            message: "Starting processing, current input: '\(inputPreview)'",
            metadata: [
                "isURL": String(isURL),
                "operation": "N/A",
                "input_length": String(manager.inputText.count)
            ],
            timestamp: Date()
        ))
    }

    /// Обрезает вход до максимальной длины, чтобы длинный текст не блокировал обработку.
    private static func truncated(_ text: String) -> String {
        String(text.prefix(ShareExtensionViewModelConstants.maxInputTextLength))
    }

    /// Сигнализирует об успехе хаптикой и закрывает расширение.
    private func notifySuccessAndClose() {
        #if canImport(UIKit) && !os(watchOS)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        shouldCloseExtension = true
    }

    private func startProcessing(operation: InventoryOperation) {
        isProcessing = true
        errorMessage = nil

        processingTask = Task { [weak self] in
            guard let self else { return }
            await runProcessingWithTimeout(operation: operation)
        }
    }

    /// Итог рабочей задачи: результат обработки либо ошибка подготовки входа
    private enum WorkOutcome {
        case finished((success: Bool, error: UserFacingError?)?)
        case failed(Error)
    }

    /// Загружает вход (страницу для URL) и обрабатывает его моделью, публикуя стадии.
    /// Выполняется целиком внутри бюджета таймаута обработки.
    private func performWork(operation: InventoryOperation) async -> WorkOutcome {
        do {
            let opType = OperationFactory.make(kind: operation.operation, logManager: logManager)
            let isURL = OperationInput.isHttpURL(string: manager.inputText)
            let input = createOperationInput(isURL: isURL)

            logOperationInput(input)

            setStage(isURL ? .fetchingPage : .askingModel)
            let resolvedText = try await opType.resolveInput(input: input)

            logResolvedInput(resolvedText)

            setStage(.askingModel)
            let result = await manager.process(text: resolvedText, operation: operation)
            return .finished(result)
        } catch {
            return .failed(error)
        }
    }

    /// Публикует стадию обработки и логирует переход
    private func setStage(_ newStage: ProcessingStage?) {
        guard stage != newStage else { return }
        stage = newStage
        logManager.log(LogEntry(
            level: .debug,
            module: "ShareExtensionViewModel",
            message: "Processing stage: \(newStage.map(String.init(describing:)) ?? "idle")",
            metadata: [:],
            timestamp: Date()
        ))
    }

    private func createOperationInput(isURL: Bool) -> OperationInput {
        if isURL {
            OperationInput(
                targetLanguage: "",
                length: SummarizeLengths.defaultLength,
                url: manager.inputText,
                text: nil
            )
        } else {
            OperationInput(
                targetLanguage: "",
                length: SummarizeLengths.defaultLength,
                url: nil,
                text: manager.inputText
            )
        }
    }

    private func logOperationInput(_ input: OperationInput) {
        self.manager.logManager.log(LogEntry(
            level: .debug,
            module: "ShareExtensionViewModel",
            message: "OperationInput created",
            metadata: [
                "isURL": String(OperationInput.isHttpURL(string: manager.inputText)),
                "url": input.url ?? "nil",
                "text_preview": input.text != nil ? String(input.text!.prefix(self.logContentLength)) : "nil"
            ],
            timestamp: Date()
        ))
    }

    private func logResolvedInput(_ resolvedText: String) {
        self.manager.logManager.log(LogEntry(
            level: .debug,
            module: "ShareExtensionViewModel",
            message: "resolveInput result: '\(String(resolvedText.prefix(100)))'",
            metadata: ["resolved_length": String(resolvedText.count)],
            timestamp: Date()
        ))
    }

    private func logTextUpdate(_ text: String) {
        let inputPreview = String(text.prefix(100))
        let isURL = OperationInput.isHttpURL(string: text)
        manager.logManager.log(LogEntry(
            level: .info,
            module: "ShareExtensionViewModel",
            message: "Input text updated: '\(inputPreview)'",
            metadata: [
                "isURL": String(isURL),
                "input_length": String(text.count),
                "type": isURL ? "URL" : "TEXT"
            ],
            timestamp: Date()
        ))
    }

    private func updateOperationsForInput(_ text: String) {
        let isURL = OperationInput.isHttpURL(string: text)

        if isURL {
            self.operations = manager.inventoryManager.inventory.filter { op in
                OperationFactory.make(kind: op.operation, logManager: manager.logManager).supportsURL
            }
            manager.logManager.log(LogEntry(
                level: .info,
                module: "ShareExtensionViewModel",
                message: "Operations filtered for URL, available: \(self.operations.count)",
                metadata: ["operations": self.operations.map(\.operation.rawValue).joined(separator: ", ")],
                timestamp: Date()
            ))
        } else {
            // Для обычного текста показываем все операции
            self.operations = manager.inventoryManager.inventory
            manager.logManager.log(LogEntry(
                level: .info,
                module: "ShareExtensionViewModel",
                message: "All operations loaded for text, available: \(self.operations.count)",
                metadata: ["operations": self.operations.map(\.operation.rawValue).joined(separator: ", ")],
                timestamp: Date()
            ))
        }
    }

    private func runProcessingWithTimeout(operation: InventoryOperation) async {
        // Запускаем две задачи: загрузка входа + обработка и таймер (общий бюджет времени)
        await withTaskGroup(of: (finishedFirst: Int, outcome: WorkOutcome?).self) { group in
            let workTask = Task<WorkOutcome, Never> {
                await self.performWork(operation: operation)
            }
            let timeoutTask = Task<Void, Never> {
                let timeoutNs = self.processingTimeoutSeconds * Double(ShareExtensionViewModelConstants.nanosecondsPerSecond)
                try? await Task.sleep(nanoseconds: UInt64(timeoutNs))
            }
            group.addTask {
                let res = await workTask.value
                return (0, res)
            }
            group.addTask {
                await timeoutTask.value
                return (1, nil)
            }
            let (finishedFirst, outcome) = await group.next() ?? (1, nil)
            workTask.cancel()
            timeoutTask.cancel()
            await MainActor.run {
                handleWorkCompletion(finishedFirst: finishedFirst, outcome: outcome)
            }
        }
    }

    private func handleWorkCompletion(finishedFirst: Int, outcome: WorkOutcome?) {
        setStage(nil)
        switch outcome {
        case let .failed(error):
            handleProcessingError(error)
        case let .finished(result):
            handleProcessingCompletion(finishedFirst: finishedFirst, result: result)
        case nil:
            handleProcessingCompletion(finishedFirst: finishedFirst, result: nil)
        }
    }

    private func handleProcessingCompletion(finishedFirst: Int, result: (success: Bool, error: UserFacingError?)?) {
        guard !hasCompleted else { return }
        hasCompleted = true
        isProcessing = false
        if finishedFirst == 1 {
            logManager.log(LogEntry(
                level: .error,
                module: "ShareExtensionViewModel",
                message: "errorMessage set in handleProcessingCompletion: Processing timeout",
                metadata: [:],
                timestamp: Date()
            ))
            if errorMessage == nil {
                lastErrorKey = .errorTimeout
                errorMessage = L10n.errorTimeout
            }
            manager.cancelProcessing()
        } else {
            handleResult(result: result)
        }
    }

    @MainActor
    private func handleResult(result: (success: Bool, error: UserFacingError?)?) {
        if let error = result?.error {
            let msg = handleUserFacingError(error)
            logManager.log(LogEntry(
                level: .error,
                module: "ShareExtensionViewModel",
                message: "errorMessage set in handleResult: \(msg)",
                metadata: [:],
                timestamp: Date()
            ))
            if errorMessage == nil {
                errorMessage = msg
            }
        } else if result?.success == true {
            if currentResultMode == .display {
                displayResult = manager.lastResult
            } else {
                notifySuccessAndClose()
            }
        }
    }

    /// Локализует ключ ошибки по таблице Localizable бандла расширения
    private func localized(_ key: UserFacingErrorKey) -> String {
        key.localized(in: Bundle(for: ShareExtensionViewModel.self))
    }

    private func handleUserFacingError(_ error: UserFacingError) -> String {
        lastErrorKey = error.messageKey
        let message = localized(error.messageKey)
        let advice = localized(error.adviceKey)
        var details = ""
        if let underlying = error.underlyingError {
            if let fetchError = underlying as? FetchError {
                details = "\n\n\(localized(fetchError.userFacingError.messageKey))"
            } else if let userError = underlying as? UserFacingError {
                details = "\n\n\(localized(userError.messageKey))"
            }
        }
        return "\(message)\n\n\(advice)\(details)"
    }

    private func handleProcessingError(_ error: Error) {
        guard !hasCompleted else { return }
        hasCompleted = true
        isProcessing = false
        let errorType = String(describing: type(of: error))
        var errorMsg: String? = nil
        if let userError = error as? UserFacingError {
            errorMsg = self.handleUserFacingError(userError)
        } else if let fetchError = error as? FetchError {
            errorMsg = self.handleUserFacingError(fetchError.userFacingError)
        } else if let localized = error as? LocalizedError, let desc = localized.errorDescription {
            lastErrorKey = .adviceUnknownError
            errorMsg = desc
        } else {
            // UserFacingError.errorDescription всегда nil — строим сообщение из ключей,
            // иначе алерт не покажется и операция «молча ничего не делает»
            errorMsg = handleUserFacingError(UserFacingError.unknown(underlyingError: error))
        }
        logManager.log(LogEntry(
            level: .error,
            module: "ShareExtensionViewModel",
            message: "errorMessage set in handleProcessingError: \(errorMsg ?? "nil")",
            metadata: [:],
            timestamp: Date()
        ))
        if errorMessage == nil {
            self.errorMessage = errorMsg
        }
        self.manager.logManager.log(LogEntry(
            level: .error,
            module: "ShareExtensionViewModel",
            message: "catch error: type=\(errorType), error=\(error), errorMessage=\(errorMsg ?? "nil")",
            metadata: [:],
            timestamp: Date()
        ))
        // Логируем ошибку (старый лог оставляю для совместимости)
        self.manager.logManager.log(LogEntry(
            level: .error,
            module: "ShareExtensionViewModel",
            message: "Error during processing: \(self.errorMessage ?? String(describing: error))",
            metadata: [:],
            timestamp: Date()
        ))
    }

    deinit {
        processingTask?.cancel()
    }
}
