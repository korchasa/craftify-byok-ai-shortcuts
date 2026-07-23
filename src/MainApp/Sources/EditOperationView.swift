import Foundation
import SwiftUI

public struct EditOperationView: View {
    @ObservedObject public var viewModel: EditOperationViewModel
    public var onSave: ((InventoryOperation) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorPalette) private var palette

    public init(viewModel: EditOperationViewModel, onSave: ((InventoryOperation) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSave = onSave
    }

    public var body: some View {
        CommonFormContainer(
            title: LocalizedStringKey(L10n.editOperationTitle),
            content: {
                EditOperationContent(viewModel: viewModel)
            },
            buttons: {
                EditOperationButtons(
                    viewModel: viewModel,
                    onSave: { op in
                        onSave?(op)
                        dismiss()
                    },
                    dismiss: dismiss
                )
            }
        )
        .background(palette.background())
    }

    private struct EditOperationContent: View {
        @ObservedObject var viewModel: EditOperationViewModel
        var body: some View {
            VStack(alignment: .leading, spacing: FormStyleConstants.sectionSpacing) {
                HStack {
                    Text(L10n.addOperationType)
                        .font(.craftifyBody).bold()
                    Spacer()
                    EditOperationTypeSection(viewModel: viewModel)
                }
                EditOperationFields(viewModel: viewModel)
                HStack {
                    Text(L10n.color)
                        .font(.craftifyBody).bold()
                    Spacer()
                    OperationColorPicker(
                        symbol: viewModel.selectedKind?.sfSymbol ?? "",
                        palette: viewModel.palette,
                        selectedHex: $viewModel.selectedColorHex,
                        accessibilityID: "edit_color_button"
                    )
                }
                .padding(.top, FormStyleConstants.sectionSpacing)
                EditOperationPromptSection(viewModel: viewModel)
            }
            .padding(.leading, FormStyleConstants.formLeadingPadding)
            .padding(.trailing, FormStyleConstants.formTrailingPadding)
        }
    }

    /// Итоговый текст системного промпта: редактируется на месте,
    /// кнопка сброса возвращает дефолт, собранный из шаблона операции
    private struct EditOperationPromptSection: View {
        @ObservedObject var viewModel: EditOperationViewModel
        @Environment(\.colorPalette) private var palette
        var body: some View {
            VStack(alignment: .leading, spacing: FormStyleConstants.dividerBottomPadding) {
                HStack {
                    Text(L10n.editOperationPrompt)
                        .font(.craftifyBody).bold()
                    Spacer()
                    Button(action: { viewModel.resetPrompt() }) {
                        Label(L10n.editOperationPromptReset, systemImage: "arrow.counterclockwise")
                            .font(.craftifyFootnote)
                    }
                    .disabled(viewModel.isPromptDefault)
                    .accessibilityIdentifier("edit_prompt_reset_button")
                }
                TextEditor(text: $viewModel.promptText)
                    .font(.craftifyFootnote)
                    .fontWeight(.regular)
                    .frame(
                        minHeight: FormStyleConstants.promptEditorMinHeight,
                        maxHeight: FormStyleConstants.promptEditorMaxHeight
                    )
                    .padding(FormStyleConstants.promptEditorInnerPadding)
                    .background(
                        RoundedRectangle(cornerRadius: FormStyleConstants.searchBarCornerRadius)
                            .stroke(palette.secondaryText().opacity(FormStyleConstants.promptEditorBorderOpacity))
                    )
                    .accessibilityIdentifier("edit_prompt_editor")
            }
            .padding(.top, FormStyleConstants.sectionSpacing)
        }
    }

    private struct EditOperationButtons: View {
        @ObservedObject var viewModel: EditOperationViewModel
        var onSave: (InventoryOperation) -> Void
        var dismiss: DismissAction
        @Environment(\.colorPalette) private var palette
        var body: some View {
            CraftifyButtonBar(backgroundColor: palette.background()) {
                Button(action: {
                    viewModel.cancel()
                    dismiss()
                }) {
                    Label(L10n.editOperationCancel, systemImage: "xmark")
                        .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                        .foregroundColor(palette.secondaryButtonText())
                }
                .buttonStyle(CraftifySecondaryButtonStyle())
                Button(action: {
                    if let op = viewModel.makeOperation() {
                        onSave(op)
                        dismiss()
                    }
                }) {
                    Label(L10n.editOperationSave, systemImage: "checkmark")
                        .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                        .foregroundColor(palette.primaryButtonText())
                }
                .buttonStyle(CraftifyPrimaryButtonStyle())
                .disabled(!viewModel.isValid)
            }
        }
    }

    private struct EditOperationTypeSection: View {
        @ObservedObject var viewModel: EditOperationViewModel
        var body: some View {
            Picker("", selection: $viewModel.selectedKind) {
                ForEach(OperationFactory.allKinds, id: \.self) { kind in
                    Text(label(for: kind)).tag(Optional(kind))
                }
            }
            .pickerStyle(DefaultPickerStyle())
            .accessibilityLabel(L10n.addOperationType)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .disabled(true)
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

    private struct EditOperationFields: View {
        @ObservedObject var viewModel: EditOperationViewModel
        var body: some View {
            switch viewModel.selectedKind {
            case .translate:
                AnyView(EditOperationTranslateSection(viewModel: viewModel))
            case .simplify:
                AnyView(EmptyView())
            case .correct:
                AnyView(EmptyView())
            case .explain:
                AnyView(EditOperationExplainSection())
            case .summarize:
                AnyView(EditOperationSummarizeSection(viewModel: viewModel))
            case .none:
                AnyView(EmptyView())
            }
        }
    }

    private struct EditOperationTranslateSection: View {
        @ObservedObject var viewModel: EditOperationViewModel
        var body: some View {
            HStack {
                Text(L10n.operationParamTargetLanguage)
                    .font(.craftifyBody).bold()
                Spacer()
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
    }

    private struct EditOperationSummarizeSection: View {
        @ObservedObject var viewModel: EditOperationViewModel
        var body: some View {
            HStack {
                Text(L10n.operationLabelSummarize)
                    .font(.craftifyBody).bold()
                Spacer()
                Picker(L10n.operationLabelSummarize, selection: $viewModel.length) {
                    ForEach(SummarizeLengths.all, id: \.self) { length in
                        Text(SummarizeLengthDisplay.label(for: length)).tag(length)
                            .lineLimit(ViewConstants.unlimitedLineLimit)
                            .fixedSize(horizontal: ViewConstants.fixedSizeHorizontal, vertical: ViewConstants.fixedSizeVertical)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
                .accessibilityLabel(L10n.operationLabelSummarize)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private struct EditOperationExplainSection: View {
        var body: some View {
            EmptyView()
        }
    }
}
