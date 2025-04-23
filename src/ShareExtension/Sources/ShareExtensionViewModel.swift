import Combine
import CraftifyShared
import Foundation

public final class ShareExtensionViewModel: ObservableObject {
    @Published public var operations: [InventoryOperation] = []
    @Published public var isProcessing: Bool = false
    @Published public var progress: Double = 0.0
    @Published public var errorMessage: String? = nil

    private let manager: ShareExtensionManager
    private var processingTask: Task<Void, Never>? = nil
    private var progressTimer: Timer?

    public init(manager: ShareExtensionManager) {
        self.manager = manager
        self.operations = manager.inventoryManager.inventory
    }

    public func process(operation: InventoryOperation) {
        guard !isProcessing else { return }
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
        processingTask = Task {
            let result = await manager.process(text: manager.inputText, operation: operation)
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                progressTimer?.invalidate()
                isProcessing = false
                progress = ShareExtensionViewModelConstants.completeProgress
                if let error = result?.error {
                    errorMessage = error
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

    deinit {
        progressTimer?.invalidate()
        processingTask?.cancel()
    }
}
