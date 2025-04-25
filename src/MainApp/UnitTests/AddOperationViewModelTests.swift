@testable import Common
@testable import MainApp
import Nimble
import XCTest

public final class AddOperationViewModelTests: XCTestCase {
    public func testInitialStateIsEmptyAndInvalid() {
        let vm = AddOperationViewModel()
        expect(vm.selectedType) == nil
        expect(vm.isValid) == false
    }

    public func testSetOperationTypeUpdatesForm() {
        let vm = AddOperationViewModel()
        vm.selectedType = .translate
        expect(vm.selectedType) == .translate
        expect(vm.isValid) == false
    }

    public func testSetParamsEnablesValidation() {
        let vm = AddOperationViewModel()
        vm.selectedType = .translate
        vm.targetLanguage = "ru"
        expect(vm.isValid) == true
    }

    public func testValidationFailsOnEmptyLanguage() {
        let vm = AddOperationViewModel()
        vm.selectedType = .translate
        vm.targetLanguage = ""
        expect(vm.isValid) == false
    }

    public func testSaveEmitsValidOperation() {
        let vm = AddOperationViewModel()
        vm.selectedType = .simplify
        vm.complexityLevel = .beginner
        expect(vm.isValid) == true
        let op = vm.makeOperation()
        expect(op != nil) == true
        expect(op?.operation) == .simplify
    }

    public func testCancelResetsState() {
        let vm = AddOperationViewModel()
        vm.selectedType = .correct
        vm.stylePreservationLevel = 2
        vm.cancel()
        expect(vm.selectedType) == nil
        expect(vm.isValid) == false
    }

    deinit {}
}
