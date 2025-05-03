@testable import Common
import Nimble
@testable import ShareExtension
import XCTest

public final class E2EShareExtensionFlowTests: XCTestCase {
    deinit {}

    private enum TestConstants {
        static let levelTwo = 2
    }

    public func testSuccessFlow() async {
        let inventory = InventoryManagerStub()
        let auth = AuthManagerStub()
        let clipboard = ClipboardManagerStub()
        let processing = ProcessingManagerStub()
        let consent = ConsentManagerStub()
        consent.setConsent(true)
        let op = InventoryOperation(operation: .translate, params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "ru")), promptTemplate: "Translate: {text}")
        inventory.saveInventory([op])
        let manager = ShareExtensionManager(
            inventoryManager: inventory,
            authManager: auth,
            clipboardManager: clipboard,
            processingManager: processing,
            consentManager: consent,
            logManager: LogManagerSharedInMemory()
        )
        let result = await manager.process(text: "Hello", operation: op)
        guard let success = result?.success else { fail("success is nil")
            return
        }
        expect(success) == true
        expect(clipboard.copiedText) == "Processed: Hello"
    }

    public func testNoTextShowsAlert() async {
        let manager = makeManager(consent: true)
        let result = await manager.process(text: "", operation: nil)
        guard let error = result?.error else { fail("error is nil")
            return
        }
        expect(error).to(contain("Нет текста для обработки"))
    }

    public func testTooLongTextShowsAlert() async {
        let manager = makeManager(consent: true)
        let op = InventoryOperation(operation: .translate, params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "ru")), promptTemplate: "T: {text}")
        let result = await manager.process(text: String(repeating: "a", count: 10001), operation: op)
        guard let error = result?.error else { fail("error is nil")
            return
        }
        expect(error).to(contain("Текст слишком длинный для обработки"))
    }

    public func testNoConsentShowsAlert() async {
        let manager = makeManager(consent: false)
        let result = await manager.process(text: "test", operation: nil)
        guard let error = result?.error else { fail("error is nil")
            return
        }
        expect(error).to(contain("Требуется согласие пользователя"))
    }

    public func testInvalidAPIKeyShowsAlert() async {
        let manager = makeManager(consent: true, apiKey: "invalid")
        let result = await manager.process(text: "test", operation: nil)
        guard let error = result?.error else { fail("error is nil")
            return
        }
        expect(error).to(contain("Неверный API-ключ"))
    }

    public func testNetworkErrorShowsAlert() async {
        let manager = makeManager(consent: true, simulateNetworkError: true)
        let op = InventoryOperation(operation: .translate, params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "ru")), promptTemplate: "T: {text}")
        let result = await manager.process(text: "Hello", operation: op)
        guard let error = result?.error else { fail("error is nil")
            return
        }
        expect(error).to(contain("Сетевая ошибка"))
    }

    public func testParsingErrorShowsAlert() async {
        let manager = makeManager(consent: true, simulateParsingError: true)
        let op = InventoryOperation(operation: .translate, params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "ru")), promptTemplate: "T: {text}")
        let result = await manager.process(text: "Hello", operation: op)
        guard let error = result?.error else { fail("error is nil")
            return
        }
        expect(error).to(contain("Ошибка парсинга"))
    }

    public func testClipboardErrorShowsAlert() async {
        let manager = makeManager(consent: true, simulateClipboardError: true)
        let op = InventoryOperation(operation: .translate, params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "ru")), promptTemplate: "T: {text}")
        let result = await manager.process(text: "test", operation: op)
        guard let error = result?.error else { fail("error is nil")
            return
        }
        expect(error).to(contain("Ошибка доступа к буферу обмена"))
    }

    public func testNetworkErrorUIFlow() async {
        let inventory = InventoryManagerStub()
        let auth = AuthManagerStub()
        let clipboard = ClipboardManagerStub()
        let processing = ProcessingManagerStub()
        processing.shouldFailNetwork = true
        let consent = ConsentManagerStub()
        consent.setConsent(true)
        let op = InventoryOperation(operation: .translate, params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "ru")), promptTemplate: "T: {text}")
        inventory.saveInventory([op])
        let manager = ShareExtensionManager(
            inventoryManager: inventory,
            authManager: auth,
            clipboardManager: clipboard,
            processingManager: processing,
            consentManager: consent,
            logManager: LogManagerSharedInMemory()
        )
        let result = await manager.process(text: "Hello", operation: op)
        guard let error = result?.error else { fail("error is nil")
            return
        }
        expect(error).to(contain("Сетевая ошибка"))
    }

    public func testProcess_URLAsText_E2E() async {
        let inventory = InventoryManagerStub()
        let auth = AuthManagerStub()
        let clipboard = ClipboardManagerStub()
        let processing = ProcessingManagerStub()
        let consent = ConsentManagerStub()
        consent.setConsent(true)
        let op = InventoryOperation(operation: .translate, params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "ru")), promptTemplate: "Translate: {text}")
        inventory.saveInventory([op])
        let manager = ShareExtensionManager(
            inventoryManager: inventory,
            authManager: auth,
            clipboardManager: clipboard,
            processingManager: processing,
            consentManager: consent,
            logManager: LogManagerSharedInMemory()
        )
        let urlString = "https://test.craftify.dev/path?q=42"
        let result = await manager.process(text: urlString, operation: op)
        guard let success = result?.success else { fail("success is nil")
            return
        }
        expect(success) == true
        expect(clipboard.copiedText) == "Processed: https://test.craftify.dev/path?q=42"
    }

    // MARK: - Helpers

    public func makeManager(consent: Bool, apiKey: String = "sk-valid-key-1234567890", simulateNetworkError: Bool = false, simulateParsingError: Bool = false, simulateClipboardError: Bool = false) -> ShareExtensionManager {
        let inventory = InventoryManagerStub()
        let auth = AuthManagerStub()
        auth.savedKey = apiKey
        let clipboard = ClipboardManagerStub()
        clipboard.shouldFail = simulateClipboardError
        let processing = ProcessingManagerStub()
        processing.shouldFailNetwork = simulateNetworkError
        processing.shouldFailParsing = simulateParsingError
        let consentManager = ConsentManagerStub()
        consentManager.setConsent(consent)
        return ShareExtensionManager(
            inventoryManager: inventory,
            authManager: auth,
            clipboardManager: clipboard,
            processingManager: processing,
            consentManager: consentManager,
            logManager: LogManagerSharedInMemory()
        )
    }
}

// Stub для медленной обработки
final class SlowProcessingManagerStub: NSObject, ProcessingManaging {
    func process(text: String, operation: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 31.0) {
            completion(.success("Processed: \(text)"))
        }
    }

    func cancel() {}
}
