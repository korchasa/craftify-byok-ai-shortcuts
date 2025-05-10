// import ShareExtension

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
        XCTAssertEqual(result?.error, UserFacingError(messageKey: .errorConsentRequired, adviceKey: .adviceContactSupport))
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
        // ExplainOperation должен возвращать режим .display
        let params = ExplainParams(detailLevel: .adult)
        let data = try! JSONEncoder().encode(params)
        let op = InventoryOperation(operation: .explain, params: data)
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

    public func testPrintEnvironment() {}
}
