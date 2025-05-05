// @testable import Common
import XCTest

public final class AddOperationViewModelTests: XCTestCase {
    public func testInitialStateIsEmptyAndInvalid() {
        let vm = AddOperationViewModel()
        XCTAssertNil(vm.selectedKind)
        XCTAssertFalse(vm.isValid)
    }

    public func testSetOperationTypeUpdatesForm() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .translate
        XCTAssertEqual(vm.selectedKind, .translate)
        XCTAssertFalse(vm.isValid)
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
        vm.complexityLevel = .schoolchild
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

    deinit {}
}
