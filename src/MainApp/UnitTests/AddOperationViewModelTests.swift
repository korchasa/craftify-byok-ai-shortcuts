@testable import Common
@testable import MainApp
import Nimble
import XCTest

public final class AddOperationViewModelTests: XCTestCase {
    public func testInitialStateIsEmptyAndInvalid() {
        let vm = AddOperationViewModel()
        expect(vm.selectedKind) == nil
        expect(vm.isValid) == false
    }

    public func testSetOperationTypeUpdatesForm() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .translate
        expect(vm.selectedKind) == .translate
        expect(vm.isValid) == false
    }

    public func testSetParamsEnablesValidation() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .translate
        vm.targetLanguage = "ru"
        expect(vm.isValid) == true
    }

    public func testValidationFailsOnEmptyLanguage() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .translate
        vm.targetLanguage = ""
        expect(vm.isValid) == false
    }

    public func testSaveEmitsValidOperation() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .simplify
        vm.complexityLevel = .schoolchild
        expect(vm.isValid) == true
        let op = vm.makeOperation()
        expect(op != nil) == true
        expect(op?.operation) == .simplify
    }

    public func testCancelResetsState() {
        let vm = AddOperationViewModel()
        vm.selectedKind = .correct
        vm.cancel()
        expect(vm.selectedKind) == nil
        expect(vm.isValid) == false
    }

    deinit {}
}
