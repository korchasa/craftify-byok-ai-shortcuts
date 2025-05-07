// @testable import Common
import XCTest

public final class EditOperationViewModelTests: XCTestCase {
    public func testInitWithTranslateOperationFillsFields() {
        let op = InventoryOperation(
            operation: .translate,
            params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "fr")),
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
            params: try! JSONEncoder().encode(CorrectParams()),
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
            colorHex: "abdda4"
        )
        let vm = EditOperationViewModel(operation: op)
        XCTAssertEqual(vm.selectedKind, OperationKind.explain)
        // Проверка значения detailLevel, если требуется
        XCTAssertTrue(vm.isValid)
    }

    public func testValidationFailsOnEmptyLanguage() {
        let op = InventoryOperation(
            operation: .translate,
            params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "")),
            colorHex: "3288bd"
        )
        let vm = EditOperationViewModel(operation: op)
        XCTAssertFalse(vm.isValid)
    }

    public func testMakeOperationReturnsUpdatedOperation() {
        let op = InventoryOperation(
            operation: .translate,
            params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "en")),
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
