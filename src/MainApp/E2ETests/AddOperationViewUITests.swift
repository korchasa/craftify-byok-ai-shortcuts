import Nimble
import SwiftUI
import XCTest
#if canImport(ViewInspector)
    @testable import Common
    @testable import MainApp
    import ViewInspector

    public final class AddOperationViewUITests: XCTestCase {
        private enum TestConstants {
            static let levelTwo = 2
        }

        public func testPickerShowsAllOperationTypes() throws {
            let viewModel = AddOperationViewModel()
            let view = AddOperationView(viewModel: viewModel)
            let picker = try view.inspect().find(ViewType.Picker.self)
            let options = try picker.findAll(ViewType.Text.self).map { try $0.string() }
            expect(options).to(contain("Перевод", "Упрощение", "Коррекция", "Объяснение"))
        }

        public func testFormFieldsAppearForTranslate() throws {
            let viewModel = AddOperationViewModel()
            viewModel.selectedType = .translate
            let view = AddOperationView(viewModel: viewModel)
            let textField = try view.inspect().find(ViewType.TextField.self)
            expect(try textField.placeholder()) == "Язык перевода"
        }

        public func testFormFieldsAppearForSimplify() throws {
            let viewModel = AddOperationViewModel()
            viewModel.selectedType = .simplify
            let view = AddOperationView(viewModel: viewModel)
            let picker = try view.inspect().find(ViewType.Picker.self)
            let options = try picker.findAll(ViewType.Text.self).map { try $0.string() }
            expect(options).to(contain("Школьник", "Студент", "Эксперт"))
        }

        public func testSaveButtonDisabledWhenInvalid() throws {
            let viewModel = AddOperationViewModel()
            let view = AddOperationView(viewModel: viewModel)
            let button = try view.inspect().find(button: L10n.addOperationSave)
            expect(try button.isDisabled()) == true
        }

        public func testSaveButtonEnabledWhenValid() throws {
            let viewModel = AddOperationViewModel()
            viewModel.selectedType = .translate
            viewModel.targetLanguage = "en"
            let view = AddOperationView(viewModel: viewModel)
            let button = try view.inspect().find(button: L10n.addOperationSave)
            expect(try button.isDisabled()) == false
        }

        public func testCancelButtonResetsForm() throws {
            let viewModel = AddOperationViewModel()
            viewModel.selectedType = .correct
            viewModel.stylePreservationLevel = TestConstants.levelTwo
            let view = AddOperationView(viewModel: viewModel)
            let button = try view.inspect().find(button: L10n.addOperationCancel)
            try button.tap()
            expect(viewModel.selectedType) == nil
        }

        public func testAccessibilityLabelsAndDynamicType() throws {
            let viewModel = AddOperationViewModel()
            let view = AddOperationView(viewModel: viewModel)
            let saveButton = try view.inspect().find(button: L10n.addOperationSave)
            let cancelButton = try view.inspect().find(button: L10n.addOperationCancel)
            // accessibilityLabel
            expect(try saveButton.accessibilityLabel()) == L10n.addOperationSave
            expect(try cancelButton.accessibilityLabel()) == L10n.addOperationCancel
            // Dynamic Type (проверка поддержки)
            let title = try view.inspect().find(text: L10n.addOperationTitle)
            let font = try title.attributes().font()
            expect(font?.supportsDynamicType ?? false) == true
        }

        deinit {}
    }

    extension AddOperationView: Inspectable {}
#endif
