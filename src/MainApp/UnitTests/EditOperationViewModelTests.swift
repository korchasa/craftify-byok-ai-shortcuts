// @testable import Common
import XCTest

public final class EditOperationViewModelTests: XCTestCase {
    public func testInitWithTranslateOperationFillsFields() {
        let op = InventoryOperation(
            operation: .translate,
            params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "fr")),
            promptTemplate: "Translate the following text to French: {text}",
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
            params: try! JSONEncoder().encode(SimplifyParams(complexityLevel: .adult)),
            promptTemplate: "Simplify the following text for an adult reader: {text}",
            colorHex: "abdda4"
        )
        let vm = EditOperationViewModel(operation: op)
        XCTAssertEqual(vm.selectedKind, OperationKind.simplify)
        XCTAssertEqual(vm.complexityLevel, .adult)
        XCTAssertTrue(vm.isValid)
    }

    public func testInitWithCorrectOperationFillsFields() {
        let op = InventoryOperation(
            operation: .correct,
            params: try! JSONEncoder().encode(CorrectParams()),
            promptTemplate: "Correct grammar and spelling: {text}",
            colorHex: "abdda4"
        )
        let vm = EditOperationViewModel(operation: op)
        XCTAssertEqual(vm.selectedKind, OperationKind.correct)
        XCTAssertTrue(vm.isValid)
    }

    public func testInitWithExplainOperationFillsFields() {
        let op = InventoryOperation(
            operation: .explain,
            params: try! JSONEncoder().encode(ExplainParams(detailLevel: .teenager)),
            promptTemplate: "Explain the following concept at teenager level: {text}",
            colorHex: "abdda4"
        )
        let vm = EditOperationViewModel(operation: op)
        XCTAssertEqual(vm.selectedKind, OperationKind.explain)
        XCTAssertEqual(vm.detailLevel, .teenager)
        XCTAssertTrue(vm.isValid)
    }

    public func testValidationFailsOnEmptyLanguage() {
        let op = InventoryOperation(
            operation: .translate,
            params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "")),
            promptTemplate: "Translate the following text to : {text}",
            colorHex: "3288bd"
        )
        let vm = EditOperationViewModel(operation: op)
        XCTAssertFalse(vm.isValid)
    }

    public func testMakeOperationReturnsUpdatedOperation() {
        let op = InventoryOperation(
            operation: .translate,
            params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "en")),
            promptTemplate: "Translate the following text to English: {text}",
            colorHex: "3288bd"
        )
        let vm = EditOperationViewModel(operation: op)
        vm.targetLanguage = "de"
        let updated = vm.makeOperation()
        XCTAssertEqual(updated?.operation, .translate)
        let params = try? JSONDecoder().decode(TranslateParams.self, from: updated!.params)
        XCTAssertEqual(params?.targetLanguage, "de")
    }

    deinit {}
}
