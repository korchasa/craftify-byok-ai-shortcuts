// import ShareExtension

import Foundation
import XCTest

/// Обработка, которая всегда падает заданной ошибкой провайдера
private final class FailingProviderProcessingStub: NSObject, ProcessingManaging {
    private let error: Error

    init(error: Error) {
        self.error = error
    }

    func process(text _: String, operation _: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void) {
        completion(.failure(error))
    }

    func cancel() {}
}

/// Обработка, которая всегда возвращает заранее заданный текст
private final class FixedResultProcessingStub: NSObject, ProcessingManaging {
    private let result: String

    init(result: String) {
        self.result = result
    }

    func process(text _: String, operation _: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void) {
        completion(.success(result))
    }

    func cancel() {}
}

public final class ShareExtensionManagerTests: XCTestCase {
    deinit {}

    /// Модель охотно завершает ответ переводом строки, а иногда и начинает с него.
    /// Ни в буфер обмена, ни на экран результата этот мусор попадать не должен.
    public func testProcess_TrimsWhitespaceAroundResult() async {
        let consentManager = ConsentManagerStub()
        consentManager.setConsent(true)
        let clipboardManager = ClipboardManagerStub()
        let manager = ShareExtensionManager(
            inventoryManager: InventoryManagerStub(),
            authManager: AuthManagerStub(key: "sk-valid-key-1234567890"),
            clipboardManager: clipboardManager,
            processingManager: FixedResultProcessingStub(result: "\n  Переведённый текст.\n\n  "),
            consentManager: consentManager,
            logManager: LogManagerSharedInMemory()
        )
        let op = InventoryOperation(operation: .translate, params: Data())
        let result = await manager.process(text: "Translated text.", operation: op)
        XCTAssertTrue(result?.success == true)
        XCTAssertEqual(clipboardManager.copiedText, "Переведённый текст.")
        XCTAssertEqual(manager.lastResult, "Переведённый текст.")
    }

    /// Переносы строк внутри результата — часть форматирования (списки, абзацы, код),
    /// и обрезка краёв не имеет права их трогать
    public func testProcess_KeepsLineBreaksInsideResult() async {
        let consentManager = ConsentManagerStub()
        consentManager.setConsent(true)
        let clipboardManager = ClipboardManagerStub()
        let manager = ShareExtensionManager(
            inventoryManager: InventoryManagerStub(),
            authManager: AuthManagerStub(key: "sk-valid-key-1234567890"),
            clipboardManager: clipboardManager,
            processingManager: FixedResultProcessingStub(result: "- первый\n- второй\n\n- третий\n"),
            consentManager: consentManager,
            logManager: LogManagerSharedInMemory()
        )
        let op = InventoryOperation(operation: .translate, params: Data())
        let result = await manager.process(text: "list", operation: op)
        XCTAssertTrue(result?.success == true)
        XCTAssertEqual(clipboardManager.copiedText, "- первый\n- второй\n\n- третий")
    }

    /// Ошибка провайдера должна доходить до пользователя своим сообщением,
    /// а не подменяться «неизвестной ошибкой»
    public func testProcess_ProviderErrorKeepsItsUserFacingMessage() async {
        let cases: [(LLMAPIClientError, UserFacingError)] = [
            (.unauthorized, UserFacingError(messageKey: .errorInvalidApiKey, adviceKey: .adviceCheckApiKey)),
            (.insufficientCredits, UserFacingError(messageKey: .errorInsufficientCredits, adviceKey: .adviceTopUpBalance)),
            (.accessDenied, UserFacingError(messageKey: .errorAccessDenied, adviceKey: .adviceCheckKeyAccess)),
            (.contentFiltered, UserFacingError(messageKey: .errorContentFiltered, adviceKey: .adviceChangeText)),
            (.contextTooLong, UserFacingError(messageKey: .errorContextTooLong, adviceKey: .adviceShortenText)),
            (.timedOut, UserFacingError(messageKey: .errorTimeout, adviceKey: .adviceTryAgainLater)),
            (.tooManyRequests, UserFacingError(messageKey: .errorRateLimited, adviceKey: .adviceTryAgainLater)),
            (.unknownModel("vendor/no-such-model"), UserFacingError(messageKey: .errorUnknownModel, adviceKey: .adviceChangeModel)),
            (.serverError, UserFacingError(messageKey: .errorProviderUnavailable, adviceKey: .adviceTryAgainLater)),
            (.badRequest("Unsupported parameter"), UserFacingError(messageKey: .errorProviderRejectedRequest, adviceKey: .adviceChangeText)),
            (.invalidResponse("Missing result/content"), UserFacingError(messageKey: .errorParsing, adviceKey: .adviceTryAgainLater)),
            (.network(URLError(.notConnectedToInternet)), UserFacingError(messageKey: .errorNetwork, adviceKey: .adviceCheckConnection)),
            (.cancelled, UserFacingError(messageKey: .errorCancelled, adviceKey: .adviceTryAgainLater))
        ]
        for (providerError, expected) in cases {
            let consentManager = ConsentManagerStub()
            consentManager.setConsent(true)
            let manager = ShareExtensionManager(
                inventoryManager: InventoryManagerStub(),
                authManager: AuthManagerStub(key: "sk-valid-key-1234567890"),
                clipboardManager: ClipboardManagerStub(),
                processingManager: FailingProviderProcessingStub(error: providerError),
                consentManager: consentManager,
                logManager: LogManagerSharedInMemory()
            )
            let op = InventoryOperation(operation: .translate, params: Data())
            let result = await manager.process(text: "Hello", operation: op)
            XCTAssertTrue(result?.success == false)
            XCTAssertEqual(result?.error, expected, "Ошибка провайдера \(providerError) показана пользователю неверно")
        }
    }

    /// Ошибка неизвестного типа остаётся «неизвестной» — это запасной путь, а не общий
    public func testProcess_UnrecognizedErrorFallsBackToUnknown() async {
        struct OpaqueError: Error {}
        let consentManager = ConsentManagerStub()
        consentManager.setConsent(true)
        let manager = ShareExtensionManager(
            inventoryManager: InventoryManagerStub(),
            authManager: AuthManagerStub(key: "sk-valid-key-1234567890"),
            clipboardManager: ClipboardManagerStub(),
            processingManager: FailingProviderProcessingStub(error: OpaqueError()),
            consentManager: consentManager,
            logManager: LogManagerSharedInMemory()
        )
        let op = InventoryOperation(operation: .translate, params: Data())
        let result = await manager.process(text: "Hello", operation: op)
        XCTAssertEqual(result?.error, UserFacingError.unknown())
    }

    public func testProcess_Success() async {
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
        let op = InventoryOperation(operation: .translate, params: Data())
        let result = await manager.process(text: "Hello", operation: op)
        XCTAssertTrue(result?.success == true)
        XCTAssertNil(result?.error)
    }

    public func testProcess_NoConsent() async {
        let inventoryManager = InventoryManagerStub()
        let authManager = AuthManagerStub(key: "sk-valid-key-1234567890")
        let clipboardManager = ClipboardManagerStub()
        let processingManager = ProcessingManagerStub()
        let consentManager = ConsentManagerStub()
        consentManager.setConsent(false)
        let manager = ShareExtensionManager(
            inventoryManager: inventoryManager,
            authManager: authManager,
            clipboardManager: clipboardManager,
            processingManager: processingManager,
            consentManager: consentManager,
            logManager: LogManagerSharedInMemory()
        )
        let op = InventoryOperation(operation: .translate, params: Data())
        let result = await manager.process(text: "Hello", operation: op)
        XCTAssertTrue(result?.success == false)
        XCTAssertEqual(result?.error, UserFacingError(messageKey: .errorConsentRequired, adviceKey: .adviceOpenAppToConsent))
    }

    public func testProcess_TextTooLong() async {
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
        let op = InventoryOperation(operation: .translate, params: Data())
        let longText = String(repeating: "a", count: ShareExtensionManager.maxTextLength + 1)
        let result = await manager.process(text: longText, operation: op)
        XCTAssertTrue(result?.success == false)
        XCTAssertEqual(result?.error, UserFacingError(messageKey: .errorTextTooLong, adviceKey: .adviceTryAgainLater))
    }

    public func testProcess_TextAtLimit() async {
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
        let op = InventoryOperation(operation: .translate, params: Data())
        let atLimitText = String(repeating: "a", count: 5000)
        let result = await manager.process(text: atLimitText, operation: op)
        XCTAssertTrue(result?.success == true)
        XCTAssertNil(result?.error)
    }

    public func testProcess_DisplayMode() async {
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
        // ExplainOperation работает без параметров
        let op = InventoryOperation(operation: .explain, params: Data())
        let result = await manager.process(text: "Test", operation: op)
        XCTAssertTrue(result?.success == true)
        XCTAssertEqual(manager.lastResult, "Processed: Test")
        // В режиме отображения не должно быть копирования: ClipboardManagerStub.copiedText остается nil
        XCTAssertNil(clipboardManager.copiedText)
    }

    public func testProcess_URLAsText() async {
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
        let op = InventoryOperation(operation: .translate, params: Data())
        let urlString = "https://example.com/some/path?query=1"
        let result = await manager.process(text: urlString, operation: op)
        XCTAssertTrue(result?.success == true)
        XCTAssertNil(result?.error)
        XCTAssertEqual(clipboardManager.copiedText, "Processed: https://example.com/some/path?query=1")
    }

    public func testProcess_MissingApiKey() async {
        let inventoryManager = InventoryManagerStub()
        let authManager = AuthManagerStub(key: nil)
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
        let op = InventoryOperation(operation: .translate, params: Data())
        let result = await manager.process(text: "Hello", operation: op)
        XCTAssertTrue(result?.success == false)
        XCTAssertEqual(result?.error, UserFacingError(messageKey: .errorApiKeyMissing, adviceKey: .adviceAddApiKeyInApp))
    }

    /// Поздний результат прогона, который был вытеснен новым запуском (повтор после таймаута),
    /// не должен ничего копировать в буфер обмена и затирать lastResult.
    public func testProcess_LateResultOfSupersededRunIsDiscarded() async {
        final class ManualProcessingStub: NSObject, ProcessingManaging {
            var stored: ((Result<String, Error>) -> Void)?
            func process(text: String, operation: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void) {
                stored = completion
            }

            func cancel() {}
        }
        let clipboard = ClipboardManagerStub()
        let processing = ManualProcessingStub()
        let consent = ConsentManagerStub()
        consent.setConsent(true)
        let manager = ShareExtensionManager(
            inventoryManager: InventoryManagerStub(),
            authManager: AuthManagerStub(key: "sk-valid-key-1234567890"),
            clipboardManager: clipboard,
            processingManager: processing,
            consentManager: consent,
            logManager: LogManagerSharedInMemory()
        )
        manager.resetCancellation() // прогон 1
        let op = InventoryOperation(operation: .translate, params: Data())
        // Прогон 1 «зависает» на continuation до ручного завершения
        let run1 = Task { await manager.process(text: "Hello", operation: op) }
        while processing.stored == nil {
            await Task.yield()
        }
        // Пользователь запускает новый прогон — поколение сдвигается
        manager.resetCancellation() // прогон 2
        // Поздний успех прогона 1 приходит уже после смены поколения
        processing.stored?(.success("STALE-RESULT"))
        let result = await run1.value
        XCTAssertNil(clipboard.copiedText)
        XCTAssertNotEqual(manager.lastResult, "STALE-RESULT")
        XCTAssertTrue(result?.success == false)
    }

    public func testPrintEnvironment() {}
}
