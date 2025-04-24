import XCTest
import CraftifyShared
@testable import ShareExtension

final class ShareExtensionViewModelTests: XCTestCase {
    func testProcess_Timeout() async {
        // Arrange: Stub менеджеры
        let inventoryManager = InventoryManagerStub()
        let authManager = AuthManagerStub(key: "sk-valid-key-1234567890")
        let clipboardManager = ClipboardManagerStub()
        let processingManager = SlowProcessingManagerStub()
        let consentManager = ConsentManagerStub()
        consentManager.setConsent(true)
        let manager = ShareExtensionManager(
            inventoryManager: inventoryManager,
            authManager: authManager,
            clipboardManager: clipboardManager,
            processingManager: processingManager,
            consentManager: consentManager
        )
        let viewModel = ShareExtensionViewModel(manager: manager)
        let op = InventoryOperation(operation: .translate, params: Data(), promptTemplate: "test")
        manager.inputText = "Hello"
        // Act: Запускаем обработку (таймаут 0.1 сек вместо 30)
        let exp = expectation(description: "Timeout")
        Task {
            await viewModel.processWithCustomTimeout(operation: op, timeout: 0.1)
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 1.0)
        // Assert: Должна быть ошибка таймаута
        XCTAssertEqual(viewModel.errorMessage, "Время обработки истекло")
    }

    func testProcess_ShowCopiedToastOnSuccess() async {
        // Arrange
        let inventoryManager = InventoryManagerStub()
        let authManager = AuthManagerStub(key: "sk-valid-key-1234567890")
        let clipboardManager = ClipboardManagerStub()
        let processingManager = ProcessingManagerStub()
        let consentManager = ConsentManagerStub()
        consentManager.setConsent(true)
        let manager = ShareExtensionManager(
            inventoryManager: inventoryManager,
            authManager: authManager,
            clipboardManager: clipboardManager,
            processingManager: processingManager,
            consentManager: consentManager
        )
        let viewModel = ShareExtensionViewModel(manager: manager)
        let op = InventoryOperation(operation: .translate, params: Data(), promptTemplate: "test")
        manager.inputText = "Hello"
        // Act
        await viewModel.process(operation: op)
        // Assert: showCopiedToast должен быть true (сразу после успешной обработки)
        XCTAssertTrue(viewModel.showCopiedToast)
        // Сбросим тост
        viewModel.hideCopiedToast()
        XCTAssertFalse(viewModel.showCopiedToast)
    }
}

// Stub для медленной обработки
final class SlowProcessingManagerStub: NSObject, ProcessingManaging {
    func process(text: String, operation: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            completion(.success("Processed: \(text)"))
        }
    }
    func cancel() {}
}

// Расширение для тестируемого ViewModel (только для теста)
extension ShareExtensionViewModel {
    @MainActor
    func processWithCustomTimeout(operation: InventoryOperation, timeout: TimeInterval) async {
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
            async let result = manager.process(text: manager.inputText, operation: operation)
            async let timeoutTask: Void = Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            let finishedFirst = await withTaskGroup(of: Int.self) { group -> Int in
                group.addTask { await result; return 0 }
                group.addTask { await timeoutTask; return 1 }
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
                        }
                    }
                }
            }
        }
    }
}