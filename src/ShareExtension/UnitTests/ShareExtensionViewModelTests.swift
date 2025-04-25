import Combine
import Common
@testable import ShareExtension
import XCTest

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
            consentManager: consentManager,
            logManager: LogManagerSharedInMemory()
        )
        let viewModel = ShareExtensionViewModel(manager: manager)
        viewModel.processingTimeoutSeconds = 0.1 // короткий таймаут для теста
        let op = InventoryOperation(operation: .translate, params: Data(), promptTemplate: "test")
        manager.inputText = "Hello"
        // Act: Запускаем обработку
        let exp = expectation(description: "Timeout")
        var cancellable: AnyCancellable?
        cancellable = viewModel.$errorMessage.sink { msg in
            if msg == "Время обработки истекло" {
                exp.fulfill()
                cancellable?.cancel()
            }
        }
        await viewModel.process(operation: op)
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
            consentManager: consentManager,
            logManager: LogManagerSharedInMemory()
        )
        let viewModel = ShareExtensionViewModel(manager: manager)
        viewModel.processingTimeoutSeconds = 2 // достаточно для успешной обработки
        let op = InventoryOperation(operation: .translate, params: Data(), promptTemplate: "test")
        manager.inputText = "Hello"
        // Act
        let exp = expectation(description: "CopiedToast")
        var cancellable: AnyCancellable?
        cancellable = viewModel.$showCopiedToast.sink { show in
            if show {
                exp.fulfill()
                cancellable?.cancel()
            }
        }
        await viewModel.process(operation: op)
        await fulfillment(of: [exp], timeout: 1.0)
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
