@testable import Common
@testable import MainApp
import Nimble
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
        expect(vm.selectedKind) == OperationKind.translate
        expect(vm.targetLanguage) == "fr"
        expect(vm.isValid) == true
    }

    public func testInitWithSimplifyOperationFillsFields() {
        let op = InventoryOperation(
            operation: .simplify,
            params: try! JSONEncoder().encode(SimplifyParams(complexityLevel: .adult)),
            promptTemplate: "Simplify the following text for an adult reader: {text}",
            colorHex: "abdda4"
        )
        let vm = EditOperationViewModel(operation: op)
        expect(vm.selectedKind) == OperationKind.simplify
        expect(vm.complexityLevel) == .adult
        expect(vm.isValid) == true
    }

    public func testInitWithCorrectOperationFillsFields() {
        let op = InventoryOperation(
            operation: .correct,
            params: try! JSONEncoder().encode(CorrectParams()),
            promptTemplate: "Correct grammar and spelling: {text}",
            colorHex: "abdda4"
        )
        let vm = EditOperationViewModel(operation: op)
        expect(vm.selectedKind) == OperationKind.correct
        expect(vm.isValid) == true
    }

    public func testInitWithExplainOperationFillsFields() {
        let op = InventoryOperation(
            operation: .explain,
            params: try! JSONEncoder().encode(ExplainParams(detailLevel: .teenager)),
            promptTemplate: "Explain the following concept at teenager level: {text}",
            colorHex: "abdda4"
        )
        let vm = EditOperationViewModel(operation: op)
        expect(vm.selectedKind) == OperationKind.explain
        expect(vm.detailLevel) == .teenager
        expect(vm.isValid) == true
    }

    public func testValidationFailsOnEmptyLanguage() {
        let op = InventoryOperation(
            operation: .translate,
            params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "")),
            promptTemplate: "Translate the following text to : {text}",
            colorHex: "3288bd"
        )
        let vm = EditOperationViewModel(operation: op)
        expect(vm.isValid) == false
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
        expect(updated?.operation) == .translate
        let params = try? JSONDecoder().decode(TranslateParams.self, from: updated!.params)
        expect(params?.targetLanguage) == "de"
    }

    deinit {}
}
