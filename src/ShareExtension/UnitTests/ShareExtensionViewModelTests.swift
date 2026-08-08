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

    func testProcess_PublishesStages() async {
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
        viewModel.processingTimeoutSeconds = 2
        let op = InventoryOperation(operation: .translate, params: Data())
        manager.inputText = "Hello"
        var stages: [ProcessingStage?] = []
        let stageCancellable = viewModel.$stage.sink { stages.append($0) }
        let exp = expectation(description: "CloseExtension")
        var closeCancellable: AnyCancellable?
        closeCancellable = viewModel.$shouldCloseExtension.sink { shouldClose in
            if shouldClose {
                exp.fulfill()
                closeCancellable?.cancel()
            }
        }
        // Act
        viewModel.process(operation: op)
        await fulfillment(of: [exp], timeout: 1.0)
        stageCancellable.cancel()
        // Assert: для текстового входа публикуется стадия запроса к модели,
        // стадия загрузки страницы не появляется, после завершения стадия сброшена
        XCTAssertTrue(stages.contains(.askingModel))
        XCTAssertFalse(stages.contains(.fetchingPage))
        XCTAssertNil(viewModel.stage)
    }

    func testRetry_ReprocessesLastOperationOnlyForTransientErrors() async {
        // Arrange: обработка всегда падает с сетевой (транзиентной) ошибкой
        final class FailingProcessingManagerStub: NSObject, ProcessingManaging {
            private(set) var calls = 0
            func process(text: String, operation: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void) {
                calls += 1
                completion(.failure(UserFacingError(messageKey: .errorNetwork, adviceKey: .adviceCheckConnection)))
            }

            func cancel() {}
        }
        let processingManager = FailingProcessingManagerStub()
        let consentManager = ConsentManagerStub()
        consentManager.setConsent(true)
        let manager = ShareExtensionManager(
            inventoryManager: InventoryManagerStub(),
            authManager: AuthManagerStub(key: "sk-valid-key-1234567890"),
            clipboardManager: ClipboardManagerStub(),
            processingManager: processingManager,
            consentManager: consentManager,
            logManager: LogManagerSharedInMemory()
        )
        let viewModel = ShareExtensionViewModel(manager: manager)
        viewModel.processingTimeoutSeconds = 2
        let op = InventoryOperation(operation: .translate, params: Data())
        manager.inputText = "Hello"

        // Act 1: первая обработка завершается транзиентной ошибкой
        let firstError = expectation(description: "First error")
        var cancellable: AnyCancellable?
        cancellable = viewModel.$errorMessage.sink { msg in
            if msg != nil {
                firstError.fulfill()
                cancellable?.cancel()
            }
        }
        viewModel.process(operation: op)
        await fulfillment(of: [firstError], timeout: 1.0)

        // Assert 1: ошибка помечена как повторяемая
        XCTAssertTrue(viewModel.isLastErrorRetryable)

        // Act 2: повтор запускает ту же операцию ещё раз
        let secondError = expectation(description: "Second error")
        var retryCancellable: AnyCancellable?
        retryCancellable = viewModel.$errorMessage.dropFirst().sink { msg in
            if msg != nil {
                secondError.fulfill()
                retryCancellable?.cancel()
            }
        }
        viewModel.retry()
        await fulfillment(of: [secondError], timeout: 1.0)
        XCTAssertEqual(processingManager.calls, 2)

        // Arrange 2: ошибка согласия — НЕ повторяемая, retry не запускает обработку
        let noConsentProcessing = FailingProcessingManagerStub()
        let noConsent = ConsentManagerStub()
        noConsent.setConsent(false)
        let noConsentManager = ShareExtensionManager(
            inventoryManager: InventoryManagerStub(),
            authManager: AuthManagerStub(key: "sk-valid-key-1234567890"),
            clipboardManager: ClipboardManagerStub(),
            processingManager: noConsentProcessing,
            consentManager: noConsent,
            logManager: LogManagerSharedInMemory()
        )
        let consentViewModel = ShareExtensionViewModel(manager: noConsentManager)
        consentViewModel.processingTimeoutSeconds = 2
        noConsentManager.inputText = "Hello"
        let consentError = expectation(description: "Consent error")
        var consentCancellable: AnyCancellable?
        consentCancellable = consentViewModel.$errorMessage.sink { msg in
            if msg != nil {
                consentError.fulfill()
                consentCancellable?.cancel()
            }
        }
        consentViewModel.process(operation: op)
        await fulfillment(of: [consentError], timeout: 1.0)
        XCTAssertFalse(consentViewModel.isLastErrorRetryable)
        consentViewModel.retry()
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(noConsentProcessing.calls, 0)
    }

    /// Отказ провайдера по ключу пользователь видит как «неверный ключ»,
    /// и повтор для него не предлагается — от повтора ключ не станет верным
    func testProcess_ProviderUnauthorizedShowsKeyErrorWithoutRetry() async {
        final class UnauthorizedProcessingStub: NSObject, ProcessingManaging {
            private(set) var calls = 0
            func process(text _: String, operation _: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void) {
                calls += 1
                completion(.failure(LLMAPIClientError.unauthorized))
            }

            func cancel() {}
        }
        let processingManager = UnauthorizedProcessingStub()
        let consentManager = ConsentManagerStub()
        consentManager.setConsent(true)
        let manager = ShareExtensionManager(
            inventoryManager: InventoryManagerStub(),
            authManager: AuthManagerStub(key: "sk-valid-key-1234567890"),
            clipboardManager: ClipboardManagerStub(),
            processingManager: processingManager,
            consentManager: consentManager,
            logManager: LogManagerSharedInMemory()
        )
        let viewModel = ShareExtensionViewModel(manager: manager)
        viewModel.processingTimeoutSeconds = 2
        manager.inputText = "Hello"

        // Act: обработка падает отказом провайдера по ключу
        let errorShown = expectation(description: "Error shown")
        var cancellable: AnyCancellable?
        cancellable = viewModel.$errorMessage.sink { msg in
            if msg != nil {
                errorShown.fulfill()
                cancellable?.cancel()
            }
        }
        viewModel.process(operation: InventoryOperation(operation: .translate, params: Data()))
        await fulfillment(of: [errorShown], timeout: 1.0)

        // Assert: показан именно ключевой текст, а не «неизвестная ошибка»
        XCTAssertEqual(viewModel.lastErrorKey, .errorInvalidApiKey)
        XCTAssertFalse(viewModel.isLastErrorRetryable)
        viewModel.retry()
        try? await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(processingManager.calls, 1)
    }

    /// У каждой ошибки провайдера должно быть своё сообщение с советом: ни одна не должна
    /// сваливаться в «неизвестную ошибку» и ни одна не должна повторять чужую пару ключей.
    /// Наличие самих переводов проверяет сверка ключей локализации в `deno task check`.
    func testEveryProviderErrorHasItsOwnMessageAndAdvice() {
        let allErrors: [LLMAPIClientError] = [
            .unauthorized, .insufficientCredits, .accessDenied, .contentFiltered,
            .contextTooLong, .timedOut, .tooManyRequests, .serverError, .cancelled,
            .badRequest("boom"), .invalidResponse("boom"), .unknownModel("vendor/model"),
            .network(URLError(.notConnectedToInternet))
        ]
        var seenPairs: Set<String> = []
        for error in allErrors {
            let userError = error.userFacingError
            XCTAssertNotEqual(userError.messageKey, .adviceUnknownError, "\(error) осталась «неизвестной ошибкой»")
            let pair = "\(userError.messageKeyString)|\(userError.adviceKeyString)"
            XCTAssertTrue(seenPairs.insert(pair).inserted, "\(error) повторяет сообщение другой ошибки: \(pair)")
        }
        // Нераспознанный ответ — единственный случай, которому нечего сказать по существу
        XCTAssertEqual(LLMAPIClientError.unknown(418).userFacingError.messageKey, .adviceUnknownError)
    }

    /// Когда провайдер отклонил запрос, его собственное объяснение попадает в алерт —
    /// без него пользователю нечего исправлять
    func testProcess_BadRequestShowsProviderExplanation() async {
        final class RejectingProcessingStub: NSObject, ProcessingManaging {
            func process(text _: String, operation _: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void) {
                completion(.failure(LLMAPIClientError.badRequest("This model does not support assistant message prefill.")))
            }

            func cancel() {}
        }
        let consentManager = ConsentManagerStub()
        consentManager.setConsent(true)
        let manager = ShareExtensionManager(
            inventoryManager: InventoryManagerStub(),
            authManager: AuthManagerStub(key: "sk-valid-key-1234567890"),
            clipboardManager: ClipboardManagerStub(),
            processingManager: RejectingProcessingStub(),
            consentManager: consentManager,
            logManager: LogManagerSharedInMemory()
        )
        let viewModel = ShareExtensionViewModel(manager: manager)
        viewModel.processingTimeoutSeconds = 2
        manager.inputText = "Hello"
        let errorShown = expectation(description: "Error shown")
        var cancellable: AnyCancellable?
        cancellable = viewModel.$errorMessage.sink { msg in
            if msg != nil {
                errorShown.fulfill()
                cancellable?.cancel()
            }
        }
        viewModel.process(operation: InventoryOperation(operation: .translate, params: Data()))
        await fulfillment(of: [errorShown], timeout: 1.0)

        XCTAssertEqual(viewModel.lastErrorKey, .errorProviderRejectedRequest)
        XCTAssertFalse(viewModel.isLastErrorRetryable)
        XCTAssertTrue(
            viewModel.errorMessage?.contains("does not support assistant message prefill") == true,
            "В алерте нет объяснения провайдера: \(viewModel.errorMessage ?? "nil")"
        )
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

    /// Экран выбора показывает, над чем работаем: вход публикуется во ViewModel
    /// и подписывается как ссылка, когда пользователь поделился ссылкой
    func testUpdateInputText_PublishesPreviewAndDetectsURL() {
        let inventoryManager = InventoryManagerStub()
        let manager = ShareExtensionManager(
            inventoryManager: inventoryManager,
            authManager: AuthManagerStub(key: "sk-valid-key-1234567890"),
            clipboardManager: ClipboardManagerStub(),
            processingManager: ProcessingManagerStub(),
            consentManager: ConsentManagerStub(),
            logManager: LogManagerSharedInMemory()
        )
        let viewModel = ShareExtensionViewModel(manager: manager)

        viewModel.updateInputText("Договор вступает в силу с момента подписания.")
        XCTAssertEqual(viewModel.inputText, "Договор вступает в силу с момента подписания.")
        XCTAssertEqual(viewModel.inputText, manager.inputText)
        XCTAssertFalse(viewModel.isInputURL)

        viewModel.updateInputText("https://example.com/article")
        XCTAssertEqual(viewModel.inputText, "https://example.com/article")
        XCTAssertTrue(viewModel.isInputURL)
    }

    /// Выделение в чужом приложении часто захватывает пробелы и перевод строки по краям.
    /// В промпт они попадать не должны: модель повторяет их в ответе.
    func testUpdateInputText_TrimsWhitespaceAroundInput() {
        let manager = ShareExtensionManager(
            inventoryManager: InventoryManagerStub(),
            authManager: AuthManagerStub(key: "sk-valid-key-1234567890"),
            clipboardManager: ClipboardManagerStub(),
            processingManager: ProcessingManagerStub(),
            consentManager: ConsentManagerStub(),
            logManager: LogManagerSharedInMemory()
        )
        let viewModel = ShareExtensionViewModel(manager: manager)

        viewModel.updateInputText("\n  Договор вступает в силу.\n\n")
        XCTAssertEqual(viewModel.inputText, "Договор вступает в силу.")
        XCTAssertEqual(manager.inputText, "Договор вступает в силу.")

        // Внутренняя разметка входа остаётся нетронутой
        viewModel.updateInputText("  первый абзац\n\nвторой абзац  ")
        XCTAssertEqual(viewModel.inputText, "первый абзац\n\nвторой абзац")
    }

    /// Слишком длинный вход обрезается одинаково и для обработки, и для шапки
    func testUpdateInputText_TruncatesPreviewLikeProcessingInput() {
        let manager = ShareExtensionManager(
            inventoryManager: InventoryManagerStub(),
            authManager: AuthManagerStub(key: "sk-valid-key-1234567890"),
            clipboardManager: ClipboardManagerStub(),
            processingManager: ProcessingManagerStub(),
            consentManager: ConsentManagerStub(),
            logManager: LogManagerSharedInMemory()
        )
        let viewModel = ShareExtensionViewModel(manager: manager)

        let long = String(repeating: "a", count: ShareExtensionViewModelConstants.maxInputTextLength + 100)
        viewModel.updateInputText(long)

        XCTAssertEqual(viewModel.inputText.count, ShareExtensionViewModelConstants.maxInputTextLength)
        XCTAssertEqual(viewModel.inputText, manager.inputText)
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
