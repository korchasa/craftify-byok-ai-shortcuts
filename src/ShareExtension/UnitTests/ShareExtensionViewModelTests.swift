import Combine
@testable import ShareExtension
import XCTest

@MainActor
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
        await MainActor.run { viewModel.processingTimeoutSeconds = 0.1 } // короткий таймаут для теста
        let op = InventoryOperation(operation: .translate, params: Data())
        manager.inputText = "Hello"
        // Act: Запускаем обработку
        let exp = expectation(description: "Timeout error should be set")
        var errorCount = 0
        var cancellable: AnyCancellable?
        cancellable = viewModel.$errorMessage.sink { msg in
            if msg != nil {
                errorCount += 1
                exp.fulfill()
                cancellable?.cancel()
            }
        }
        viewModel.process(operation: op)
        await fulfillment(of: [exp], timeout: 1.0)
        try? await Task.sleep(nanoseconds: 100_000_000) // 100 мс
        // Assert: Должна быть установлена ошибка (любая)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(errorCount, 1)
    }

    func testProcess_ClosesExtensionOnSuccess() async {
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
        let exp = expectation(description: "CloseExtension")
        var cancellable: AnyCancellable?
        cancellable = viewModel.$shouldCloseExtension.sink { shouldClose in
            if shouldClose {
                exp.fulfill()
                cancellable?.cancel()
            }
        }
        viewModel.process(operation: op)
        await fulfillment(of: [exp], timeout: 1.0)
        // Assert: после успешной обработки в режиме clipboard расширение закрывается
        XCTAssertTrue(viewModel.shouldCloseExtension)
        XCTAssertNil(viewModel.errorMessage)
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

        // Должны остаться только операции, поддерживающие URL (Summarize и Simplify)
        XCTAssertEqual(viewModel.operations.count, 2)
        let kindsForURL = viewModel.operations.map(\.operation)
        XCTAssertTrue(kindsForURL.contains(.summarize))
        XCTAssertTrue(kindsForURL.contains(.simplify))

        // 3. Обновляем inputText на обычный текст и проверяем, что отображаются все операции
        viewModel.updateInputText("Просто текст")
        XCTAssertEqual(viewModel.operations.count, allOps.count)
    }

    func testUpdateInputText_TruncatesAndFiltersOperations() {
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

        // Assert - Текст обрезан до лимита, обработка остаётся доступной
        XCTAssertEqual(manager.inputText.count, ShareExtensionViewModelConstants.maxInputTextLength)
        XCTAssertEqual(manager.inputText, String(longText.prefix(ShareExtensionViewModelConstants.maxInputTextLength)))

        // Act - Устанавливаем URL
        let urlText = "https://example.com"
        viewModel.updateInputText(urlText)

        // Assert - Короткий вход не изменяется и операции отфильтрованы
        XCTAssertEqual(manager.inputText, urlText)
        XCTAssertEqual(viewModel.operations.count, 2)
        let kindsURL2 = viewModel.operations.map(\.operation)
        XCTAssertTrue(kindsURL2.contains(.summarize))
        XCTAssertTrue(kindsURL2.contains(.simplify))
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
        await MainActor.run { viewModel.processingTimeoutSeconds = 0.1 }
        let op = InventoryOperation(operation: .translate, params: Data())
        manager.inputText = "Hello"
        // Act
        let exp = expectation(description: "Only one error should be set")
        var errorCount = 0
        var cancellable: AnyCancellable?
        cancellable = viewModel.$errorMessage.sink { msg in
            if msg != nil {
                errorCount += 1
                exp.fulfill()
                cancellable?.cancel()
            }
        }
        viewModel.process(operation: op)
        await fulfillment(of: [exp], timeout: 1.0)
        try? await Task.sleep(nanoseconds: 100_000_000) // 100 мс
        // Assert: Ошибка должна быть установлена только один раз
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(errorCount, 1)
    }

    func testCopyDisplayedResultAndClose_CopiesAndCloses() {
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

        // Предварительно устанавливаем отображаемый результат
        let expectedText = """
        **Первый абзац:** Это *Markdown*-текст, который содержит **выделение** и `код`.

        Второй абзац содержит ссылку: [Craftify](https://example.com).
        """
        viewModel.displayResult = expectedText

        // Act
        viewModel.copyDisplayedResultAndClose()

        // Assert
        XCTAssertEqual(clipboardManager.copiedText, expectedText)
        XCTAssertTrue(viewModel.shouldCloseExtension)
    }
}

/// Stub для медленной обработки
final class SlowProcessingManagerStub: NSObject, ProcessingManaging {
    func process(text: String, operation: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            completion(.success("Processed: \(text)"))
        }
    }

    func cancel() {}
}
