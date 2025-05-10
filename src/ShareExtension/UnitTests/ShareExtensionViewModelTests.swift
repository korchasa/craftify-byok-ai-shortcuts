import Combine
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
        let op = InventoryOperation(operation: .translate, params: Data())
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
        viewModel.process(operation: op)
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
        let op = InventoryOperation(operation: .translate, params: Data())
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
        viewModel.process(operation: op)
        await fulfillment(of: [exp], timeout: 1.0)
        // Assert: showCopiedToast должен быть true (сразу после успешной обработки)
        XCTAssertTrue(viewModel.showCopiedToast)
        // Сбросим тост
        viewModel.hideCopiedToast()
        XCTAssertFalse(viewModel.showCopiedToast)
    }

    func testOperations_FilteredForURLInput() {
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
        // Заполняем inventory всеми типами операций
        let allKinds = OperationKind.allCases
        let palette = ["ff807d", "89e1c5", "3288bd", "f7b801", "e14eca"]
        var colorIdx = 0
        func nextColor() -> String {
            defer { colorIdx = (colorIdx + 1) % palette.count }
            return palette[colorIdx]
        }
        let allOps: [InventoryOperation] = allKinds.compactMap { kind in
            OperationFactory.make(kind: kind).makeInventoryOperation(input: OperationInput(), colorHex: nextColor())
        }
        inventoryManager.saveInventory(allOps)

        // Создаем ViewModel с начальным пустым вводом
        let viewModel = ShareExtensionViewModel(manager: manager)

        // 1. Изначально должны загрузиться все операции
        XCTAssertEqual(viewModel.operations.count, allOps.count)

        // 2. Обновляем inputText на URL и проверяем, что операции отфильтрованы
        viewModel.updateInputText("https://example.com")

        // Должна остаться только SummarizeOperation
        XCTAssertEqual(viewModel.operations.count, 1)
        XCTAssertEqual(viewModel.operations.first?.operation, .summarize)

        // 3. Обновляем inputText на обычный текст и проверяем, что отображаются все операции
        viewModel.updateInputText("Просто текст")
        XCTAssertEqual(viewModel.operations.count, allOps.count)
    }

    func testUpdateInputText_ChangesFlagAndFiltersOperations() {
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
        let allOps: [InventoryOperation] = OperationKind.allCases.compactMap { kind in
            OperationFactory.make(kind: kind).makeInventoryOperation(input: OperationInput(), colorHex: "ffffff")
        }
        inventoryManager.saveInventory(allOps)

        let viewModel = ShareExtensionViewModel(manager: manager)

        // Act - Устанавливаем слишком длинный текст
        let longText = String(repeating: "a", count: ShareExtensionViewModelConstants.maxInputTextLength + 1)
        viewModel.updateInputText(longText)

        // Assert - Флаг должен быть установлен
        XCTAssertTrue(viewModel.isInputTextTooLong)
        XCTAssertEqual(manager.inputText, longText)

        // Act - Устанавливаем URL
        let urlText = "https://example.com"
        viewModel.updateInputText(urlText)

        // Assert - Флаг сброшен и операции отфильтрованы
        XCTAssertFalse(viewModel.isInputTextTooLong)
        XCTAssertEqual(manager.inputText, urlText)
        XCTAssertEqual(viewModel.operations.count, 1)
        XCTAssertEqual(viewModel.operations.first?.operation, .summarize)
    }

    func testProcess_ErrorAndTimeoutRace_OnlyOneError() async {
        // Arrange: Менеджер, который завершает обработку с ошибкой чуть позже таймаута
        class RacingProcessingManagerStub: NSObject, ProcessingManaging {
            func process(text: String, operation: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void) {
                // Завершить с ошибкой через 0.2 сек
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                    completion(.failure(UserFacingError(messageKey: .errorParsing, adviceKey: .adviceTryAgainLater)))
                }
            }

            func cancel() {}
        }
        let inventoryManager = InventoryManagerStub()
        let authManager = AuthManagerStub(key: "sk-valid-key-1234567890")
        let clipboardManager = ClipboardManagerStub()
        let processingManager = RacingProcessingManagerStub()
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
        viewModel.processingTimeoutSeconds = 0.1 // таймаут сработает чуть раньше
        let op = InventoryOperation(operation: .translate, params: Data())
        manager.inputText = "Hello"
        // Act
        let exp = expectation(description: "Only one error should be set")
        var errorCount = 0
        var cancellable: AnyCancellable?
        cancellable = viewModel.$errorMessage.sink { msg in
            if msg != nil { errorCount += 1 }
        }
        viewModel.process(operation: op)
        // Ждем чуть больше, чем оба события
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 1.0)
        cancellable?.cancel()
        // Assert: Ошибка должна быть установлена только один раз
        XCTAssertEqual(errorCount, 1)
        XCTAssertEqual(viewModel.errorMessage, "Время обработки истекло")
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
