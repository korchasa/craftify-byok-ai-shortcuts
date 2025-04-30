import Nimble
import SwiftUI
import XCTest
#if canImport(ViewInspector)
    @testable import Common
    @testable import MainApp
    import ViewInspector

    public final class EditOperationViewUITests: XCTestCase {
        private enum TestConstants {
            static let levelOne = 1
            static let levelTwo = 2
            static let levelThree = 3
        }

        public func testFieldsAppearForTranslate() throws {
            let op = InventoryOperation(
                operation: .translate,
                params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "es")),
                promptTemplate: "Translate the following text to Spanish: {text}"
            )
            let vm = EditOperationViewModel(operation: op)
            let view = EditOperationView(viewModel: vm)
            let textField = try view.inspect().find(ViewType.TextField.self)
            expect(try textField.text()) == "es"
        }

        public func testFieldsAppearForSimplify() throws {
            let op = InventoryOperation(
                operation: .simplify,
                params: try! JSONEncoder().encode(SimplifyParams(complexityLevel: .intermediate)),
                promptTemplate: "Simplify the following text for an intermediate reader: {text}"
            )
            let vm = EditOperationViewModel(operation: op)
            let view = EditOperationView(viewModel: vm)
            let picker = try view.inspect().find(ViewType.Picker.self)
            let options = try picker.findAll(ViewType.Text.self).map { try $0.string() }
            expect(options).to(contain("Школьник", "Студент", "Эксперт"))
        }

        public func testFieldsAppearForCorrect() throws {
            let op = InventoryOperation(
                operation: .correct,
                params: try! JSONEncoder().encode(CorrectParams(stylePreservationLevel: TestConstants.levelThree)),
                promptTemplate: "Correct grammar and spelling, preserve style level \(TestConstants.levelThree): {text}"
            )
            let vm = EditOperationViewModel(operation: op)
            let view = EditOperationView(viewModel: vm)
            let stepper = try view.inspect().find(ViewType.Stepper.self)
            let label = try stepper.labelView().text().string()
            expect(label).to(contain("\(TestConstants.levelThree)/\(TestConstants.levelThree)"))
        }

        public func testFieldsAppearForExplain() throws {
            let op = InventoryOperation(
                operation: .explain,
                params: try! JSONEncoder().encode(ExplainParams(detailLevel: .advanced)),
                promptTemplate: "Explain the following concept at advanced level: {text}"
            )
            let vm = EditOperationViewModel(operation: op)
            let view = EditOperationView(viewModel: vm)
            let picker = try view.inspect().find(ViewType.Picker.self)
            let options = try picker.findAll(ViewType.Text.self).map { try $0.string() }
            expect(options).to(contain("Школьник", "Студент", "Эксперт"))
        }

        public func testSaveButtonEnabledWhenValid() throws {
            let op = InventoryOperation(
                operation: .translate,
                params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "en")),
                promptTemplate: "Translate the following text to English: {text}"
            )
            let vm = EditOperationViewModel(operation: op)
            let view = EditOperationView(viewModel: vm)
            let button = try view.inspect().find(button: L10n.editOperationSave)
            expect(try button.isDisabled()) == false
        }

        public func testSaveButtonDisabledWhenInvalid() throws {
            let op = InventoryOperation(
                operation: .translate,
                params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "")),
                promptTemplate: "Translate the following text to : {text}"
            )
            let vm = EditOperationViewModel(operation: op)
            let view = EditOperationView(viewModel: vm)
            let button = try view.inspect().find(button: L10n.editOperationSave)
            expect(try button.isDisabled()) == true
        }

        public func testCancelButtonResetsForm() throws {
            let op = InventoryOperation(
                operation: .correct,
                params: try! JSONEncoder().encode(CorrectParams(stylePreservationLevel: TestConstants.levelTwo)),
                promptTemplate: "Correct grammar and spelling, preserve style level \(TestConstants.levelTwo): {text}"
            )
            let vm = EditOperationViewModel(operation: op)
            vm.stylePreservationLevel = TestConstants.levelOne
            let view = EditOperationView(viewModel: vm)
            let button = try view.inspect().find(button: L10n.editOperationCancel)
            try button.tap()
            expect(vm.stylePreservationLevel) == TestConstants.levelTwo
        }

        public func testAccessibilityLabelsAndDynamicType() throws {
            let op = InventoryOperation(
                operation: .translate,
                params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "en")),
                promptTemplate: "Translate the following text to English: {text}"
            )
            let vm = EditOperationViewModel(operation: op)
            let view = EditOperationView(viewModel: vm)
            let saveButton = try view.inspect().find(button: L10n.editOperationSave)
            let cancelButton = try view.inspect().find(button: L10n.editOperationCancel)
            // accessibilityLabel
            expect(try saveButton.accessibilityLabel()) == L10n.editOperationSave
            expect(try cancelButton.accessibilityLabel()) == L10n.editOperationCancel
            // Dynamic Type (проверка поддержки)
            let title = try view.inspect().find(text: L10n.editOperationTitle)
            let font = try title.attributes().font()
            expect(font?.supportsDynamicType ?? false) == true
        }

        public func testOnSaveCalledWithCorrectOperation() throws {
            let op = InventoryOperation(
                operation: .translate,
                params: try! JSONEncoder().encode(TranslateParams(targetLanguage: "fr")),
                promptTemplate: "Translate the following text to French: {text}",
                colorHex: "3288bd"
            )
            let vm = EditOperationViewModel(operation: op)
            var savedOperation: InventoryOperation? = nil
            let view = EditOperationView(viewModel: vm, onSave: { savedOperation = $0 })
            let button = try view.inspect().find(button: L10n.editOperationSave)
            try button.tap()
            expect(savedOperation).toNot(beNil())
            expect(savedOperation?.operation) == .translate
            expect(savedOperation?.colorHex) == "3288bd"
            let params = try JSONDecoder().decode(TranslateParams.self, from: savedOperation!.params)
            expect(params.targetLanguage) == "fr"
        }

        deinit {}
    }

    extension EditOperationView: Inspectable {}
#endif
