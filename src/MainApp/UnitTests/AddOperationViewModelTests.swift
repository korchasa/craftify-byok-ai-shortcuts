import XCTest

public final class AddOperationViewModelTests: XCTestCase {
    public func testSetOperationTypeUpdatesForm() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .translate
        XCTAssertEqual(vm.selectedKind, .translate)
        XCTAssertTrue(vm.isValid)
    }

    public func testSetParamsEnablesValidation() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .translate
        vm.targetLanguage = "ru"
        XCTAssertTrue(vm.isValid)
    }

    public func testValidationFailsOnEmptyLanguage() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .translate
        vm.targetLanguage = ""
        XCTAssertFalse(vm.isValid)
    }

    public func testSaveEmitsValidOperation() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .simplify
        XCTAssertTrue(vm.isValid)
        let op = vm.makeOperation()
        XCTAssertNotNil(op)
        XCTAssertEqual(op?.operation, .simplify)
    }

    public func testCancelResetsState() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .correct
        vm.cancel()
        XCTAssertNil(vm.selectedKind)
        XCTAssertFalse(vm.isValid)
    }

    public func testFieldsResetOnOperationTypeChange() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .translate
        vm.targetLanguage = "ru"
        vm.length = "9-10 sentences"
        // Смена типа
        vm.selectedKind = .simplify
        XCTAssertEqual(vm.targetLanguage, "")
        XCTAssertEqual(vm.length, "2-3 sentences")
        // Смена на translate снова
        vm.selectedKind = .translate
        XCTAssertEqual(vm.targetLanguage, vm.supportedLanguages.first?.code ?? "")
        XCTAssertEqual(vm.length, "2-3 sentences")
    }

    public func testDefaultSelectedKindIsNotNilAndFormIsValid() {
        let vm = AddOperationViewModel()
        XCTAssertNotNil(vm.selectedKind)
        XCTAssertTrue(vm.isValid)
    }

    deinit {}
}
