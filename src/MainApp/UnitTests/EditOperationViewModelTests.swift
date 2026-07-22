import XCTest

public final class EditOperationViewModelTests: XCTestCase {
    public func testInitWithTranslateOperationFillsFields() throws {
        let op = try InventoryOperation(
            operation: .translate,
            params: JSONEncoder().encode(TranslateParams(targetLanguage: "fr")),
            colorHex: "3288bd"
        )
        let vm = EditOperationViewModel(operation: op)
        XCTAssertEqual(vm.selectedKind, OperationKind.translate)
        XCTAssertEqual(vm.targetLanguage, "fr")
        XCTAssertTrue(vm.isValid)
    }

    public func testInitWithSimplifyOperationFillsFields() {
        let op = InventoryOperation(
            operation: .simplify,
            params: Data(),
            colorHex: "abdda4"
        )
        let vm = EditOperationViewModel(operation: op)
        XCTAssertEqual(vm.selectedKind, OperationKind.simplify)
        // Проверка значения complexityLevel, если требуется
        XCTAssertTrue(vm.isValid)
    }

    public func testInitWithCorrectOperationFillsFields() {
        let op = InventoryOperation(
            operation: .correct,
            params: Data(),
            colorHex: "abdda4"
        )
        let vm = EditOperationViewModel(operation: op)
        XCTAssertEqual(vm.selectedKind, OperationKind.correct)
        XCTAssertTrue(vm.isValid)
    }

    public func testInitWithExplainOperationFillsFields() {
        let op = InventoryOperation(
            operation: .explain,
            params: Data(),
            colorHex: "abdda4"
        )
        let vm = EditOperationViewModel(operation: op)
        XCTAssertEqual(vm.selectedKind, OperationKind.explain)
        // Проверка значения detailLevel, если требуется
        XCTAssertTrue(vm.isValid)
    }

    public func testValidationFailsOnEmptyLanguage() throws {
        let op = try InventoryOperation(
            operation: .translate,
            params: JSONEncoder().encode(TranslateParams(targetLanguage: "")),
            colorHex: "3288bd"
        )
        let vm = EditOperationViewModel(operation: op)
        XCTAssertFalse(vm.isValid)
    }

    public func testMakeOperationReturnsUpdatedOperation() throws {
        let op = try InventoryOperation(
            operation: .translate,
            params: JSONEncoder().encode(TranslateParams(targetLanguage: "en")),
            colorHex: "3288bd"
        )
        let vm = EditOperationViewModel(operation: op)
        vm.targetLanguage = "de"
        let updated = vm.makeOperation()
        XCTAssertEqual(updated?.operation, .translate)
        let params = try? JSONDecoder().decode(TranslateParams.self, from: try XCTUnwrap(updated?.params))
        XCTAssertEqual(params?.targetLanguage, "de")
    }

    // MARK: - Пользовательский промпт

    public func testPromptInitializedWithDefaultWhenNoCustom() throws {
        let op = try InventoryOperation(
            operation: .translate,
            params: JSONEncoder().encode(TranslateParams(targetLanguage: "fr")),
            colorHex: "3288bd"
        )
        let vm = EditOperationViewModel(operation: op)
        XCTAssertEqual(vm.promptText, vm.currentDefaultPrompt)
        XCTAssertTrue(vm.isPromptDefault)
    }

    public func testPromptInitializedWithCustomWhenPresent() throws {
        let op = try InventoryOperation(
            operation: .translate,
            params: JSONEncoder().encode(TranslateParams(targetLanguage: "fr")),
            colorHex: "3288bd",
            customPrompt: "Translate rudely"
        )
        let vm = EditOperationViewModel(operation: op)
        XCTAssertEqual(vm.promptText, "Translate rudely")
        XCTAssertFalse(vm.isPromptDefault)
    }

    public func testResetPromptRestoresTemplateDefault() throws {
        let op = try InventoryOperation(
            operation: .translate,
            params: JSONEncoder().encode(TranslateParams(targetLanguage: "fr")),
            colorHex: "3288bd",
            customPrompt: "Translate rudely"
        )
        let vm = EditOperationViewModel(operation: op)
        vm.resetPrompt()
        XCTAssertEqual(vm.promptText, vm.currentDefaultPrompt)
        XCTAssertTrue(vm.isPromptDefault)
    }

    public func testLanguageChangeRegeneratesDefaultPromptWhenNotCustomized() throws {
        let op = try InventoryOperation(
            operation: .translate,
            params: JSONEncoder().encode(TranslateParams(targetLanguage: "fr")),
            colorHex: "3288bd"
        )
        let vm = EditOperationViewModel(operation: op)
        vm.targetLanguage = "de"
        XCTAssertTrue(vm.promptText.contains("German"), "Prompt should follow the new language: \(vm.promptText)")
    }

    public func testLanguageChangeKeepsCustomizedPrompt() throws {
        let op = try InventoryOperation(
            operation: .translate,
            params: JSONEncoder().encode(TranslateParams(targetLanguage: "fr")),
            colorHex: "3288bd",
            customPrompt: "Translate rudely"
        )
        let vm = EditOperationViewModel(operation: op)
        vm.targetLanguage = "de"
        XCTAssertEqual(vm.promptText, "Translate rudely")
    }

    public func testMakeOperationStoresNilForDefaultPromptAndTextForCustom() throws {
        let op = try InventoryOperation(
            operation: .translate,
            params: JSONEncoder().encode(TranslateParams(targetLanguage: "fr")),
            colorHex: "3288bd"
        )
        let vm = EditOperationViewModel(operation: op)
        XCTAssertNil(vm.makeOperation()?.customPrompt)
        vm.promptText = "Translate rudely"
        XCTAssertEqual(vm.makeOperation()?.customPrompt, "Translate rudely")
    }

    deinit {}
}
