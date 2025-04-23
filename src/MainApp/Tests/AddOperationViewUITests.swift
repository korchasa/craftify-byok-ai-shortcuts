import Nimble
import SwiftUI
import XCTest
#if canImport(ViewInspector)
    @testable import CraftifyShared
    @testable import MainApp
    import ViewInspector

    public final class AddOperationViewUITests: XCTestCase {
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
            viewModel.stylePreservationLevel = 2
            let view = AddOperationView(viewModel: viewModel)
            let button = try view.inspect().find(button: L10n.addOperationCancel)
            try button.tap()
            expect(viewModel.selectedType) == nil
        }

        deinit {}
    }

    extension AddOperationView: Inspectable {}
#endif
