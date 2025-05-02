import Common
import Nimble
@testable import ShareExtension
import XCTest

public final class ShareExtensionManagerTests: XCTestCase {
    deinit {}
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
        let op = InventoryOperation(operation: .translate, params: Data(), promptTemplate: "test")
        let result = await manager.process(text: "Hello", operation: op)
        expect(result?.success) == true
        expect(result?.error).to(beNil())
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
        let op = InventoryOperation(operation: .translate, params: Data(), promptTemplate: "test")
        let result = await manager.process(text: "Hello", operation: op)
        expect(result?.success) == false
        expect(result?.error) == "Требуется согласие пользователя"
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
        let op = InventoryOperation(operation: .translate, params: Data(), promptTemplate: "test")
        let longText = String(repeating: "a", count: 5001)
        let result = await manager.process(text: longText, operation: op)
        expect(result?.success) == false
        expect(result?.error) == "Текст слишком длинный для обработки"
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
        let op = InventoryOperation(operation: .translate, params: Data(), promptTemplate: "test")
        let atLimitText = String(repeating: "a", count: 5000)
        let result = await manager.process(text: atLimitText, operation: op)
        expect(result?.success) == true
        expect(result?.error).to(beNil())
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
        // ExplainOperation должен возвращать режим .display
        let params = ExplainParams(detailLevel: .adult)
        let data = try! JSONEncoder().encode(params)
        let op = InventoryOperation(operation: .explain, params: data, promptTemplate: "ExplainPrompt")
        let result = await manager.process(text: "Test", operation: op)
        expect(result?.success) == true
        expect(manager.lastResult) == "Processed: Test"
        // В режиме отображения не должно быть копирования: ClipboardManagerStub.copiedText остается nil
        expect(clipboardManager.copiedText).to(beNil())
    }
}
