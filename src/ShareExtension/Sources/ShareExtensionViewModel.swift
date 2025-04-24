import Combine
import CraftifyShared
import Foundation

public final class ShareExtensionViewModel: ObservableObject {
    @Published public var operations: [InventoryOperation] = []
    @Published public var isProcessing: Bool = false
    @Published public var progress: Double = 0.0
    @Published public var errorMessage: String? = nil
    @Published public var isInputTextTooLong: Bool = false
    @Published public var showCopiedToast: Bool = false

    private let manager: ShareExtensionManager
    private var processingTask: Task<Void, Never>? = nil
    private var progressTimer: Timer?

    public init(manager: ShareExtensionManager) {
        self.manager = manager
        self.operations = manager.inventoryManager.inventory
        self.isInputTextTooLong = manager.inputText.count > 5000
    }

    public func process(operation: InventoryOperation) {
        guard !isProcessing else { return }
        if manager.inputText.count > 5000 {
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
            guard let self else { return }
            // Запускаем обработку и таймер 30 с параллельно
            async let result = manager.process(text: manager.inputText, operation: operation)
            async let timeout: Void = Task.sleep(nanoseconds: 30_000_000_000)
            let finishedFirst = await withTaskGroup(of: Int.self) { group -> Int in
                group.addTask { await result; return 0 }
                group.addTask { await timeout; return 1 }
                let first = await group.next() ?? 0
                group.cancelAll()
                return first
            }
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                progressTimer?.invalidate()
                isProcessing = false
                if finishedFirst == 1 {
                    errorMessage = "Время обработки истекло"
                    manager.cancelProcessing()
                    progress = 0.0
                } else {
                    progress = ShareExtensionViewModelConstants.completeProgress
                    Task { [weak self] in
                        guard let self else { return }
                        let res = await result
                        if let error = res?.error {
                            errorMessage = error
                        } else if res?.success == true {
                            showCopiedToast = true
                        }
                    }
                }
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
        isInputTextTooLong = text.count > 5000
    }

    public func hideCopiedToast() {
        showCopiedToast = false
    }

    deinit {
        progressTimer?.invalidate()
        processingTask?.cancel()
    }
}
