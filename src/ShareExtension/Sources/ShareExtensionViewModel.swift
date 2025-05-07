import Combine
import Foundation
import SwiftUI

public final class ShareExtensionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published public var operations: [InventoryOperation] = []
    @Published public var isProcessing: Bool = false
    @Published public var progress: Double = 0.0
    @Published public var errorMessage: String? = nil
    @Published public var isInputTextTooLong: Bool = false
    @Published public var showCopiedToast: Bool = false
    @Published public var displayResult: String? = nil
    @Published public var shouldCloseExtension: Bool = false

    // MARK: - Properties
    public let manager: ShareExtensionManager
    private var currentResultMode: ResultMode = .clipboard
    public var processingTask: Task<Void, Never>? = nil
    public var progressTimer: Timer?
    public var processingTimeoutSeconds: Double = 30
    private var logManager: LogManagerShared { manager.logManager }

    // MARK: - Initialization
    public init(manager: ShareExtensionManager) {
        self.manager = manager
        let input = manager.inputText
        let inputPreview = String(input.prefix(100))

        // Добавляем дополнительное логирование для отладки
        manager.logManager.log(LogEntry(
            level: .debug,
            module: "ShareExtensionViewModel",
            message: "Инициализация ShareExtensionViewModel, исходный ввод: '\(inputPreview)'",
            metadata: ["input_length": String(input.count)],
            timestamp: Date()
        ))

        // Загружаем все операции по умолчанию, а затем отфильтруем их в updateInputText когда будет доступен контент
        self.operations = manager.inventoryManager.inventory
        self.isInputTextTooLong = input.count > ShareExtensionViewModelConstants.maxInputTextLength
    }

    // MARK: - Public Methods
    public func process(operation: InventoryOperation) {
        guard !isProcessing else { return }

        logProcessingStart()

        currentResultMode = OperationFactory.make(kind: operation.operation, logManager: self.logManager).resultMode
        displayResult = nil

        if validateInputTextLength() {
            return
        }

        startProcessing(operation: operation)
    }

    public func updateInputText(_ text: String) {
        manager.inputText = text
        isInputTextTooLong = text.count > ShareExtensionViewModelConstants.maxInputTextLength

        logTextUpdate(text)
        updateOperationsForInput(text)
    }

    public func cancel() {
        processingTask?.cancel()
        manager.cancelProcessing()
        isProcessing = false
        progressTimer?.invalidate()
        progress = 0.0
    }

    public func hideCopiedToast() {
        showCopiedToast = false
        shouldCloseExtension = true
    }

    // MARK: - Private Methods
    private func logProcessingStart() {
        let inputPreview = String(manager.inputText.prefix(100))
        let isURL = OperationInput.isHttpURL(string: manager.inputText)
        manager.logManager.log(LogEntry(
            level: .debug,
            module: "ShareExtensionViewModel",
            message: "Начинаем обработку, текущий ввод: '\(inputPreview)'",
            metadata: [
                "isURL": String(isURL),
                "operation": "N/A",
                "input_length": String(manager.inputText.count)
            ],
            timestamp: Date()
        ))
    }

    private func validateInputTextLength() -> Bool {
        if manager.inputText.count > ShareExtensionViewModelConstants.maxInputTextLength {
            errorMessage = "Текст слишком длинный для обработки"
            return true
        }
        return false
    }

    private func startProcessing(operation: InventoryOperation) {
        isProcessing = true
        progress = 0.0
        errorMessage = nil
        startProgressTimer()

        processingTask = Task { [weak self] in
            guard let self else { return }
            do {
                let opType = OperationFactory.make(kind: operation.operation, logManager: logManager)
                let input = createOperationInput(isURL: OperationInput.isHttpURL(string: manager.inputText))

                logOperationInput(input)

                let resolvedText = try await opType.resolveInput(input: input)

                logResolvedInput(resolvedText)

                await runProcessingWithTimeout(operation: operation, resolvedText: resolvedText)
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = error.localizedDescription

                    // Логируем ошибку
                    self.manager.logManager.log(LogEntry(
                        level: .error,
                        module: "ShareExtensionViewModel",
                        message: "Ошибка при обработке: \(error.localizedDescription)",
                        metadata: [:],
                        timestamp: Date()
                    ))
                }
            }
        }
    }

    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: ShareExtensionViewModelConstants.progressInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            if progress < ShareExtensionViewModelConstants.maxProgress {
                progress += ShareExtensionViewModelConstants.progressStep
            }
        }
    }

    private func createOperationInput(isURL: Bool) -> OperationInput {
        if isURL {
            return OperationInput(
                targetLanguage: "",
                complexityLevel: .schoolchild,
                detailLevel: .schoolchild,
                sentenceCountRange: .twoToThree,
                url: manager.inputText,
                text: nil
            )
        } else {
            return OperationInput(
                targetLanguage: "",
                complexityLevel: .schoolchild,
                detailLevel: .schoolchild,
                sentenceCountRange: .twoToThree,
                url: nil,
                text: manager.inputText
            )
        }
    }

    private func logOperationInput(_ input: OperationInput) {
        self.manager.logManager.log(LogEntry(
            level: .debug,
            module: "ShareExtensionViewModel",
            message: "Сформирован OperationInput",
            metadata: [
                "isURL": String(OperationInput.isHttpURL(string: manager.inputText)),
                "url": input.url ?? "nil",
                "text_preview": input.text != nil ? String(input.text!.prefix(50)) : "nil"
            ],
            timestamp: Date()
        ))
    }

    private func logResolvedInput(_ resolvedText: String) {
        self.manager.logManager.log(LogEntry(
            level: .debug,
            module: "ShareExtensionViewModel",
            message: "Результат resolveInput: '\(String(resolvedText.prefix(100)))'",
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
            message: "Обновлен входной текст: '\(inputPreview)'",
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
                message: "Отфильтрованы операции для URL, доступно: \(self.operations.count)",
                metadata: ["operations": self.operations.map { $0.operation.rawValue }.joined(separator: ", ")],
                timestamp: Date()
            ))
        } else {
            // Для обычного текста показываем все операции
            self.operations = manager.inventoryManager.inventory
            manager.logManager.log(LogEntry(
                level: .info,
                module: "ShareExtensionViewModel",
                message: "Загружены все операции для текста, доступно: \(self.operations.count)",
                metadata: ["operations": self.operations.map { $0.operation.rawValue }.joined(separator: ", ")],
                timestamp: Date()
            ))
        }
    }

    private func runProcessingWithTimeout(operation: InventoryOperation, resolvedText: String) async {
        // Запускаем две задачи: обработка и таймер
        await withTaskGroup(of: (finishedFirst: Int, result: (success: Bool, error: String?)?).self) { group in
            let processingTask = Task<(success: Bool, error: String?)?, Never> {
                await self.manager.process(text: resolvedText, operation: operation)
            }
            let timeoutTask = Task<Void, Never> {
                let timeoutNs = self.processingTimeoutSeconds * Double(ShareExtensionViewModelConstants.nanosecondsPerSecond)
                try? await Task.sleep(nanoseconds: UInt64(timeoutNs))
            }
            group.addTask {
                let res = await processingTask.value
                return (0, res)
            }
            group.addTask {
                await timeoutTask.value
                return (1, nil)
            }
            let (finishedFirst, result) = await group.next() ?? (1, nil)
            processingTask.cancel()
            timeoutTask.cancel()
            await MainActor.run {
                handleProcessingCompletion(finishedFirst: finishedFirst, result: result)
            }
        }
    }

    private func handleProcessingCompletion(finishedFirst: Int, result: (success: Bool, error: String?)?) {
        progressTimer?.invalidate()
        isProcessing = false
        if finishedFirst == 1 {
            errorMessage = "Время обработки истекло"
            manager.cancelProcessing()
            progress = 0.0
        } else {
            progress = ShareExtensionViewModelConstants.completeProgress
            Task { [weak self] in
                self?.handleResult(result: result)
            }
        }
    }

    private func handleResult(result: (success: Bool, error: String?)?) {
        if let error = result?.error {
            errorMessage = error
        } else if result?.success == true {
            if currentResultMode == .display {
                displayResult = manager.lastResult
            } else {
                showCopiedToast = true
                shouldCloseExtension = true
            }
        }
    }

    deinit {
        progressTimer?.invalidate()
        processingTask?.cancel()
    }
}
