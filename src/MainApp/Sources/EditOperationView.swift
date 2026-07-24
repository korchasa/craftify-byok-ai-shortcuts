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
            content: { availableHeight in
                EditOperationContent(viewModel: viewModel, availableHeight: availableHeight)
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
        @Environment(\.colorPalette) private var palette
        /// Высота листа под прокруткой, приходит из CommonFormContainer
        let availableHeight: CGFloat
        /// Замеренная высота строк над редактором (тип, поля, цвет, заголовок)
        @State private var headerHeight: CGFloat = 0

        /// Высота блока строк над редактором — для адаптивной высоты редактора
        private struct EditHeaderHeightKey: PreferenceKey {
            static var defaultValue: CGFloat = 0
            static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
                value = max(value, nextValue())
            }
        }

        /// Редактор заполняет остаток листа, а на коротком экране (ландшафт,
        /// крупный шрифт) зажимается до минимума — тогда вся форма прокручивается
        /// и строки над промптом уходят за верхний край
        private var editorHeight: CGFloat {
            let chromeBelowHeader = FormStyleConstants.dividerBottomPadding
                + FormStyleConstants.promptEditorInnerPadding
                + FormStyleConstants.promptEditorInnerPadding
            let fill = availableHeight - headerHeight - chromeBelowHeader
            return max(FormStyleConstants.promptEditorMinHeight, fill)
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(key: EditHeaderHeightKey.self, value: geo.size.height)
                        }
                    )
                promptEditor
            }
            .padding(.leading, FormStyleConstants.formLeadingPadding)
            .padding(.trailing, FormStyleConstants.formTrailingPadding)
            .onPreferenceChange(EditHeaderHeightKey.self) { headerHeight = $0 }
        }

        /// Строки над редактором: тип операции, параметры, цвет и заголовок промпта
        private var header: some View {
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
            }
        }

        /// Итоговый текст системного промпта: редактируется на месте и прокручивается
        /// внутри себя; кнопка сброса возвращает дефолт из шаблона операции
        private var promptEditor: some View {
            TextEditor(text: $viewModel.promptText)
                .font(.craftifyFootnote)
                .fontWeight(.regular)
                .frame(height: editorHeight)
                .padding(FormStyleConstants.promptEditorInnerPadding)
                .background(
                    RoundedRectangle(cornerRadius: FormStyleConstants.searchBarCornerRadius)
                        .stroke(palette.secondaryText().opacity(FormStyleConstants.promptEditorBorderOpacity))
                )
                .padding(.top, FormStyleConstants.dividerBottomPadding)
                .accessibilityIdentifier("edit_prompt_editor")
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
                        .foregroundColor(.primary)
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
        @Environment(\.colorPalette) private var palette
        var body: some View {
            // Тип операции при редактировании неизменяем: показываем как статичный
            // текст без пикера и шеврона, чтобы не намекать на возможность смены
            Text(viewModel.selectedKind.map { label(for: $0) } ?? "")
                .font(.craftifyBody)
                .foregroundColor(palette.secondaryText())
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityLabel(L10n.addOperationType)
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
                Text(L10n.operationParamLength)
                    .font(.craftifyBody).bold()
                Spacer()
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

    private struct EditOperationExplainSection: View {
        var body: some View {
            EmptyView()
        }
    }
}
