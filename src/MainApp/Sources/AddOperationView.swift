import Foundation
import SwiftUI

public struct AddOperationView: View {
    @ObservedObject public var viewModel: AddOperationViewModel
    @Environment(\.dismiss) private var dismiss
    public var onSave: ((InventoryOperation) -> Void)?

    public init(viewModel: AddOperationViewModel, onSave: ((InventoryOperation) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSave = onSave
    }

    public var body: some View {
        CommonFormContainer(
            title: LocalizedStringKey(L10n.addOperationTitle),
            content: { _ in
                VStack(alignment: .leading, spacing: FormStyleConstants.sectionSpacing) {
                    HStack {
                        Text(L10n.addOperationType)
                            .font(.craftifyBody).bold()
                        Spacer()
                        AddOperationTypeSection(viewModel: viewModel)
                    }
                    AddOperationFields(viewModel: viewModel)
                    HStack {
                        Text(L10n.color)
                            .font(.craftifyBody).bold()
                        Spacer()
                        OperationColorPicker(
                            symbol: viewModel.selectedKind?.sfSymbol ?? "",
                            palette: viewModel.palette,
                            selectedHex: $viewModel.selectedColorHex,
                            accessibilityID: "add_color_button"
                        )
                    }
                }
                .padding(.leading, FormStyleConstants.formLeadingPadding)
                .padding(.trailing, FormStyleConstants.formTrailingPadding)
            },
            buttons: {
                AddOperationButtons(viewModel: viewModel, onSave: onSave, dismiss: dismiss)
            }
        )
    }

    private struct AddOperationButtons: View {
        @ObservedObject var viewModel: AddOperationViewModel
        var onSave: ((InventoryOperation) -> Void)?
        var dismiss: DismissAction
        @Environment(\.colorPalette) private var palette
        var body: some View {
            CraftifyButtonBar(backgroundColor: palette.background()) {
                cancelButton
                saveButton
            }
        }

        private var cancelButton: some View {
            Button(action: {
                viewModel.cancel()
                dismiss()
            }) {
                Label(L10n.addOperationCancel, systemImage: "xmark")
                    .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                    .foregroundColor(.primary)
            }
            .buttonStyle(CraftifySecondaryButtonStyle())
        }

        private var saveButton: some View {
            Button(action: {
                if let op = viewModel.makeOperation() {
                    onSave?(op)
                    dismiss()
                }
            }) {
                Label(L10n.addOperationSave, systemImage: "checkmark")
                    .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                    .foregroundColor(palette.primaryButtonText())
            }
            .buttonStyle(CraftifyPrimaryButtonStyle())
            .disabled(!viewModel.isValid)
        }
    }

    private struct AddOperationTypeSection: View {
        @ObservedObject var viewModel: AddOperationViewModel
        var body: some View {
            Picker("", selection: $viewModel.selectedKind) {
                ForEach(OperationFactory.allKinds, id: \.self) { kind in
                    Text(label(for: kind)).tag(Optional(kind))
                }
            }
            .pickerStyle(DefaultPickerStyle())
            .accessibilityLabel(L10n.addOperationType)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }

        private func label(for kind: OperationKind) -> String {
            switch kind {
            case .translate: L10n.operationLabelTranslate
            case .simplify: L10n.operationLabelSimplify
            case .correct: L10n.operationLabelCorrect
            case .explain: L10n.operationLabelExplain
            case .summarize: L10n.operationLabelSummarize
            }
        }
    }

    private struct AddOperationFields: View {
        @ObservedObject var viewModel: AddOperationViewModel
        var body: some View {
            switch viewModel.selectedKind {
            case .translate:
                translateSection
            case .simplify:
                EmptyView()
            case .correct:
                EmptyView()
            case .explain:
                explainSection
            case .summarize:
                summarizeSection
            case .none:
                EmptyView()
            }
        }

        private var translateSection: some View {
            HStack {
                Text(L10n.operationParamTargetLanguage)
                    .font(.craftifyBody).bold()
                Spacer()
                AddOperationTranslateSection(viewModel: viewModel)
            }
        }

        private var explainSection: some View {
            HStack {
                Text("")
                Spacer()
            }
        }

        private var summarizeSection: some View {
            HStack {
                Text(L10n.operationParamLength)
                    .font(.craftifyBody).bold()
                Spacer()
                AddOperationSummarizeSection(viewModel: viewModel)
            }
        }
    }

    private struct AddOperationTranslateSection: View {
        @ObservedObject var viewModel: AddOperationViewModel
        var body: some View {
            Picker(L10n.operationParamTargetLanguage, selection: $viewModel.targetLanguage) {
                ForEach(viewModel.supportedLanguages, id: \.code) { lang in
                    Text(lang.name).tag(lang.code)
                }
            }
            .pickerStyle(DefaultPickerStyle())
            .accessibilityLabel(L10n.operationParamTargetLanguage)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private struct AddOperationSummarizeSection: View {
        @ObservedObject var viewModel: AddOperationViewModel
        var body: some View {
            Picker(L10n.operationParamLength, selection: $viewModel.length) {
                ForEach(SummarizeLengths.all, id: \.self) { length in
                    Text(SummarizeLengthDisplay.label(for: length)).tag(length)
                        .lineLimit(ViewConstants.unlimitedLineLimit)
                        .fixedSize(horizontal: ViewConstants.fixedSizeHorizontal, vertical: ViewConstants.fixedSizeVertical)
                }
            }
            .pickerStyle(DefaultPickerStyle())
            .accessibilityLabel(L10n.operationParamLength)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
