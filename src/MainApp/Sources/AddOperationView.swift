import Foundation
import SwiftUI

public struct AddOperationView: View {
    @ObservedObject public var viewModel: AddOperationViewModel
    @Environment(\.dismiss) private var dismiss
    public var onSave: ((InventoryOperation) -> Void)? = nil

    private let supportedLanguages: [(name: String, code: String)] = [
        ("русский", "ru"),
        ("english", "en"),
        ("español", "es"),
        ("français", "fr"),
        ("deutsch", "de"),
        ("中文", "zh"),
        ("日本語", "ja"),
        ("українська", "uk"),
        ("български", "bg")
    ]

    private let colorPaletteVerticalPadding: CGFloat = 8

    public init(viewModel: AddOperationViewModel, onSave: ((InventoryOperation) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSave = onSave
    }

    public var body: some View {
        CommonFormContainer(
            title: LocalizedStringKey(L10n.addOperationTitle),
            content: {
                VStack(alignment: .leading, spacing: FormStyleConstants.sectionSpacing) {
                    HStack {
                        Text(L10n.addOperationType)
                            .font(.title2).bold()
                        Spacer()
                        AddOperationTypeSection(viewModel: viewModel)
                    }
                    HStack {
                        Text(L10n.operationParamDetailLevel)
                            .font(.title2).bold()
                        Spacer()
                        AddOperationExplainSection(viewModel: viewModel)
                    }
                    Text(L10n.color)
                        .font(.title2).bold()
                        .padding(.top, FormStyleConstants.sectionSpacing)
                    AddOperationColorPalette(viewModel: viewModel)
                }
                .padding(.horizontal, FormStyleConstants.formLeadingPadding)
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
        var body: some View {
            CraftifyButtonBar {
                Button(action: {
                    viewModel.cancel()
                    dismiss()
                }) {
                    Label(L10n.addOperationCancel, systemImage: "xmark")
                        .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                }
                .buttonStyle(CraftifySecondaryButtonStyle())
                Button(action: {
                    if let op = viewModel.makeOperation() {
                        onSave?(op)
                        dismiss()
                    }
                }) {
                    Label(L10n.addOperationSave, systemImage: "checkmark")
                        .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                }
                .buttonStyle(CraftifyPrimaryButtonStyle())
                .disabled(!viewModel.isValid)
            }
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
            Group {
                switch viewModel.selectedKind {
                case .translate:
                    AddOperationTranslateSection(viewModel: viewModel)
                case .simplify:
                    AddOperationSimplifySection(viewModel: viewModel)
                case .correct:
                    EmptyView()
                case .explain:
                    AddOperationExplainSection(viewModel: viewModel)
                case .summarize:
                    AddOperationSummarizeSection(viewModel: viewModel)
                case .none:
                    EmptyView()
                }
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

    private struct AddOperationSimplifySection: View {
        @ObservedObject var viewModel: AddOperationViewModel
        var body: some View {
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

    private struct AddOperationExplainSection: View {
        @ObservedObject var viewModel: AddOperationViewModel
        var body: some View {
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

    private struct AddOperationSummarizeSection: View {
        @ObservedObject var viewModel: AddOperationViewModel
        var body: some View {
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

        private func sentenceCountRangeLabel(_ range: SentenceCountRange) -> String {
            switch range {
            case .twoToThree: L10n.sentenceCount23
            case .fiveToSix: L10n.sentenceCount56
            case .nineToTen: L10n.sentenceCount910
            }
        }
    }

    private struct AddOperationColorPalette: View {
        @ObservedObject var viewModel: AddOperationViewModel
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ColorPaletteConstants.circleSpacing) {
                    ForEach(AddOperationViewModel.palette, id: \.self) { hex in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: ColorPaletteConstants.circleSize, height: ColorPaletteConstants.circleSize)
                            .overlay(
                                Circle()
                                    .stroke(viewModel.selectedColorHex == hex ? Color.accentColor : .clear, lineWidth: ColorPaletteConstants.borderWidth)
                            )
                            .onTapGesture {
                                viewModel.selectedColorHex = hex
                            }
                            .accessibilityLabel("Цвет #\(hex)")
                            .accessibilityAddTraits(viewModel.selectedColorHex == hex ? [.isButton, .isSelected] : [.isButton])
                    }
                }
                .padding(.vertical, ColorPaletteConstants.verticalSpacing)
            }
        }
    }
}
