import Foundation
import SwiftUI

public struct EditOperationView: View {
    @ObservedObject public var viewModel: EditOperationViewModel
    public var onSave: ((InventoryOperation) -> Void)?
    public var onDelete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorPalette) private var palette
    @State private var showDeleteConfirmation = false

    public init(viewModel: EditOperationViewModel, onSave: ((InventoryOperation) -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSave = onSave
        self.onDelete = onDelete
    }

    public var body: some View {
        CommonFormContainer(
            title: LocalizedStringKey(L10n.editOperationTitle),
            content: {
                EditOperationContent(
                    viewModel: viewModel,
                    onDelete: onDelete,
                    showDeleteConfirmation: $showDeleteConfirmation,
                    dismiss: dismiss
                )
            },
            buttons: {
                EditOperationButtons(viewModel: viewModel, onSave: { op in
                    onSave?(op)
                    dismiss()
                }, dismiss: dismiss)
            }
        )
        .background(palette.background())
    }

    private struct EditOperationContent: View {
        @ObservedObject var viewModel: EditOperationViewModel
        let onDelete: (() -> Void)?
        @Binding var showDeleteConfirmation: Bool
        var dismiss: DismissAction
        var body: some View {
            VStack(alignment: .leading, spacing: FormStyleConstants.sectionSpacing) {
                HStack {
                    Text(L10n.addOperationType)
                        .font(.craftifyBody).bold()
                    Spacer()
                    EditOperationTypeSection(viewModel: viewModel)
                }
                EditOperationFields(viewModel: viewModel)
                Text(L10n.color)
                    .font(.craftifyBody).bold()
                    .padding(.top, FormStyleConstants.sectionSpacing)
                EditOperationColorPalette(viewModel: viewModel)
                if let onDelete {
                    EditOperationDeleteSection(
                        showDeleteConfirmation: $showDeleteConfirmation,
                        onDelete: onDelete,
                        dismiss: dismiss
                    )
                }
            }
            .padding(.leading, FormStyleConstants.formLeadingPadding)
            .padding(.trailing, FormStyleConstants.formTrailingPadding)
        }
    }

    private struct EditOperationDeleteSection: View {
        @Binding var showDeleteConfirmation: Bool
        let onDelete: () -> Void
        var dismiss: DismissAction
        @Environment(\.colorPalette) private var palette
        var body: some View {
            Divider()
            Button(role: .destructive, action: {
                showDeleteConfirmation = true
            }) {
                Label(L10n.homeDelete, systemImage: "trash")
                    .font(.craftifyBody)
                    .fontWeight(.bold)
                    .foregroundColor(palette.destructive())
            }
            .accessibilityLabel(L10n.homeDelete)
            .padding(.top, FormStyleConstants.sectionSpacing)
            .alert(
                LocalizedStringKey(L10n.homeDelete),
                isPresented: $showDeleteConfirmation,
                actions: {
                    Button(role: .destructive, action: {
                        onDelete()
                        dismiss()
                    }) {
                        Text(LocalizedStringKey(L10n.homeDelete))
                    }
                    Button(role: .cancel, action: {}) {
                        Text(LocalizedStringKey("Cancel"))
                    }
                },
                message: {
                    Text(LocalizedStringKey("Вы уверены, что хотите удалить операцию?"))
                }
            )
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
            Group {
                switch viewModel.selectedKind {
                case .translate:
                    EditOperationTranslateSection(viewModel: viewModel)
                case .simplify:
                    EditOperationSimplifySection(viewModel: viewModel)
                case .correct:
                    EmptyView()
                case .explain:
                    EditOperationExplainSection(viewModel: viewModel)
                case .summarize:
                    EditOperationSummarizeSection(viewModel: viewModel)
                case .none:
                    EmptyView()
                }
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

    private struct EditOperationSimplifySection: View {
        @ObservedObject var viewModel: EditOperationViewModel
        var body: some View {
            HStack {
                Text(L10n.operationParamComplexityLevel)
                    .font(.craftifyBody).bold()
                Spacer()
                Picker(L10n.operationParamComplexityLevel, selection: $viewModel.complexityLevel) {
                    Text(L10n.operationValueSchoolchild).tag(ComplexityLevel.schoolchild)
                    Text(L10n.operationValueTeenager).tag(ComplexityLevel.teenager)
                    Text(L10n.operationValueStudent).tag(ComplexityLevel.student)
                    Text(L10n.operationValueAdult).tag(ComplexityLevel.adult)
                }
                .pickerStyle(DefaultPickerStyle())
                .accessibilityLabel(L10n.operationParamComplexityLevel)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private struct EditOperationExplainSection: View {
        @ObservedObject var viewModel: EditOperationViewModel
        var body: some View {
            HStack {
                Text(L10n.operationParamDetailLevel)
                    .font(.craftifyBody).bold()
                Spacer()
                Picker("", selection: $viewModel.detailLevel) {
                    Text(L10n.operationValueSchoolchild).tag(DetailLevel.schoolchild)
                    Text(L10n.operationValueTeenager).tag(DetailLevel.teenager)
                    Text(L10n.operationValueStudent).tag(DetailLevel.student)
                    Text(L10n.operationValueAdult).tag(DetailLevel.adult)
                }
                .pickerStyle(DefaultPickerStyle())
                .accessibilityLabel(L10n.operationParamDetailLevel)
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
                Picker(L10n.operationLabelSummarize, selection: $viewModel.sentenceCountRange) {
                    ForEach(SentenceCountRange.allCases, id: \.self) { range in
                        Text(sentenceCountRangeLabel(range)).tag(range)
                            .lineLimit(ViewConstants.unlimitedLineLimit)
                            .fixedSize(horizontal: ViewConstants.fixedSizeHorizontal, vertical: ViewConstants.fixedSizeVertical)
                    }
                }
                .pickerStyle(DefaultPickerStyle())
                .accessibilityLabel(L10n.operationLabelSummarize)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }

        private func sentenceCountRangeLabel(_ range: SentenceCountRange) -> String {
            switch range {
            case .twoToThree: L10n.sentenceCount23
            case .fiveToSix: L10n.sentenceCount56
            case .nineToTen: L10n.sentenceCount910
            }
        }
    }

    private struct EditOperationColorPalette: View {
        @ObservedObject var viewModel: EditOperationViewModel
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ColorPickerLayoutConstants.circleSpacing) {
                    ForEach(viewModel.palette, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: ColorPickerLayoutConstants.circleSize, height: ColorPickerLayoutConstants.circleSize)
                            .overlay(
                                Circle()
                                    .stroke(viewModel.selectedColorHex == hex ? Color.accentColor : .clear, lineWidth: ColorPickerLayoutConstants.borderWidth)
                            )
                            .onTapGesture {
                                viewModel.selectedColorHex = hex
                            }
                            .accessibilityLabel("Цвет #\(hex)")
                            .accessibilityAddTraits(viewModel.selectedColorHex == hex ? [.isButton, .isSelected] : [.isButton])
                    }
                }
                .padding(.vertical, ColorPickerLayoutConstants.verticalSpacing)
            }
        }
    }
}
