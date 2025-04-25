@testable import Common
@testable import MainApp
import Nimble
import XCTest

public final class EditOperationViewModelTests: XCTestCase {
    private enum TestConstants {
        static let levelTwo = 2
        static let levelThree = 3
    }

    public func testInitWithTranslateOperationFillsFields() {
        let op = InventoryOperation(
            operation: .translate,
            params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "fr")),
            promptTemplate: "Translate the following text to French: {text}"
        )
        let vm = EditOperationViewModel(operation: op)
        expect(vm.selectedType) == .translate
        expect(vm.targetLanguage) == "fr"
        expect(vm.isValid) == true
    }

    public func testInitWithSimplifyOperationFillsFields() {
        let op = InventoryOperation(
            operation: .simplify,
            params: try! JSONEncoder().encode(SimplifyParams(complexityLevel: .advanced)),
            promptTemplate: "Simplify the following text for an advanced reader: {text}"
        )
        let vm = EditOperationViewModel(operation: op)
        expect(vm.selectedType) == .simplify
        expect(vm.complexityLevel) == .advanced
        expect(vm.isValid) == true
    }

    public func testInitWithCorrectOperationFillsFields() {
        let op = InventoryOperation(
            operation: .correct,
            params: try! JSONEncoder().encode(CorrectParams(stylePreservationLevel: TestConstants.levelTwo)),
            promptTemplate: "Correct grammar and spelling, preserve style level \(TestConstants.levelTwo): {text}"
        )
        let vm = EditOperationViewModel(operation: op)
        expect(vm.selectedType) == .correct
        expect(vm.stylePreservationLevel) == TestConstants.levelTwo
        expect(vm.isValid) == true
    }

    public func testInitWithExplainOperationFillsFields() {
        let op = InventoryOperation(
            operation: .explain,
            params: try! JSONEncoder().encode(ExplainParams(detailLevel: .intermediate)),
            promptTemplate: "Explain the following concept at intermediate level: {text}"
        )
        let vm = EditOperationViewModel(operation: op)
        expect(vm.selectedType) == .explain
        expect(vm.detailLevel) == .intermediate
        expect(vm.isValid) == true
    }

    public func testValidationFailsOnEmptyLanguage() {
        let op = InventoryOperation(
            operation: .translate,
            params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "")),
            promptTemplate: "Translate the following text to : {text}"
        )
        let vm = EditOperationViewModel(operation: op)
        expect(vm.isValid) == false
    }

    public func testMakeOperationReturnsUpdatedOperation() {
        let op = InventoryOperation(
            operation: .translate,
            params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "en")),
            promptTemplate: "Translate the following text to English: {text}"
        )
        let vm = EditOperationViewModel(operation: op)
        vm.targetLanguage = "de"
        let updated = vm.makeOperation()
        expect(updated?.operation) == .translate
        let params = try? JSONDecoder().decode(TranslateParams.self, from: updated!.params)
        expect(params?.targetLanguage) == "de"
    }

    public func testCancelResetsFields() {
        let op = InventoryOperation(
            operation: .correct,
            params: try! JSONEncoder().encode(CorrectParams(stylePreservationLevel: TestConstants.levelTwo)),
            promptTemplate: "Correct grammar and spelling, preserve style level \(TestConstants.levelTwo): {text}"
        )
        let vm = EditOperationViewModel(operation: op)
        vm.stylePreservationLevel = TestConstants.levelThree
        vm.cancel()
        expect(vm.selectedType) == .correct
        expect(vm.stylePreservationLevel) == TestConstants.levelTwo // возвращается к исходному значению
    }

    deinit {}
}
