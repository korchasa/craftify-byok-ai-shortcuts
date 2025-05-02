import Combine
import Common
import Foundation

public final class ShareExtensionViewModel: ObservableObject {
    @Published public var operations: [InventoryOperation] = []
    @Published public var isProcessing: Bool = false
    @Published public var progress: Double = 0.0
    @Published public var errorMessage: String? = nil
    @Published public var isInputTextTooLong: Bool = false
    @Published public var showCopiedToast: Bool = false
    @Published public var displayResult: String? = nil
    @Published public var shouldCloseExtension: Bool = false

    public let manager: ShareExtensionManager
    private var currentResultMode: ResultMode = .clipboard
    public var processingTask: Task<Void, Never>? = nil
    public var progressTimer: Timer?
    public var processingTimeoutSeconds: Double = 30

    public init(manager: ShareExtensionManager) {
        self.manager = manager
        self.operations = manager.inventoryManager.inventory
        self.isInputTextTooLong = manager.inputText.count > ShareExtensionViewModelConstants.maxInputTextLength
    }

    public func process(operation: InventoryOperation) {
        guard !isProcessing else { return }
        currentResultMode = OperationFactory.make(kind: operation.operation).resultMode
        displayResult = nil
        if manager.inputText.count > ShareExtensionViewModelConstants.maxInputTextLength {
            errorMessage = "Текст слишком длинный для обработки"
            return
        }
        isProcessing = true
        progress = 0.0
        errorMessage = nil
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: ShareExtensionViewModelConstants.progressInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            if progress < ShareExtensionViewModelConstants.maxProgress {
                progress += ShareExtensionViewModelConstants.progressStep
            }
        }
        processingTask = Task { [weak self] in
            await self?.runProcessingWithTimeout(operation: operation)
        }
    }

    private func runProcessingWithTimeout(operation: InventoryOperation) async {
        // Запускаем две задачи: обработка и таймер
        await withTaskGroup(of: (finishedFirst: Int, result: (success: Bool, error: String?)?).self) { group in
            let processingTask = Task<(success: Bool, error: String?)?, Never> {
                await self.manager.process(text: self.manager.inputText, operation: operation)
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

    public func cancel() {
        processingTask?.cancel()
        manager.cancelProcessing()
        isProcessing = false
        progressTimer?.invalidate()
        progress = 0.0
    }

    public func updateInputText(_ text: String) {
        manager.inputText = text
        isInputTextTooLong = text.count > ShareExtensionViewModelConstants.maxInputTextLength
    }

    public func hideCopiedToast() {
        showCopiedToast = false
        shouldCloseExtension = true
    }

    deinit {
        progressTimer?.invalidate()
        processingTask?.cancel()
    }
}
