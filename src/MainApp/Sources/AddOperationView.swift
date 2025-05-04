import Common
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
                Section(header: Text(L10n.addOperationType).font(.craftifyTitle).fontWeight(.bold)) {
                    AddOperationTypeSection(viewModel: viewModel)
                }
                Section {
                    AddOperationFields(viewModel: viewModel)
                }
                Section(header: Text(L10n.color).font(.craftifyTitle).fontWeight(.bold)) {
                    AddOperationColorPalette(viewModel: viewModel)
                }
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
            HStack(spacing: MainAppButtonConstants.horizontalPadding) {
                Button(action: {
                    viewModel.cancel()
                    dismiss()
                }) {
                    Label(L10n.addOperationCancel, systemImage: "xmark")
                        .font(.craftifyBody)
                        .fontWeight(.bold)
                }
                .buttonStyle(CraftifySecondaryButtonStyle())
                .accessibilityLabel(L10n.addOperationCancel)
                Button(action: {
                    if let op = viewModel.makeOperation() {
                        onSave?(op)
                        dismiss()
                    }
                }) {
                    Label(L10n.addOperationSave, systemImage: "checkmark")
                        .font(.craftifyBody)
                        .fontWeight(.bold)
                }
                .buttonStyle(CraftifyPrimaryButtonStyle())
                .accessibilityLabel(L10n.addOperationSave)
                .disabled(!viewModel.isValid)
            }
        }
    }

    private struct AddOperationTypeSection: View {
        @ObservedObject var viewModel: AddOperationViewModel
        var body: some View {
            Picker(L10n.addOperationType, selection: $viewModel.selectedKind) {
                ForEach(OperationFactory.allKinds, id: \.self) { kind in
                    Text(label(for: kind)).tag(Optional(kind))
                }
            }
            .pickerStyle(DefaultPickerStyle())
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
        }
    }

    private struct AddOperationExplainSection: View {
        @ObservedObject var viewModel: AddOperationViewModel
        var body: some View {
            Picker(L10n.operationParamDetailLevel, selection: $viewModel.detailLevel) {
                Text(L10n.operationValueSchoolchild).tag(DetailLevel.schoolchild)
                Text(L10n.operationValueTeenager).tag(DetailLevel.teenager)
                Text(L10n.operationValueStudent).tag(DetailLevel.student)
                Text(L10n.operationValueAdult).tag(DetailLevel.adult)
            }
            .pickerStyle(DefaultPickerStyle())
            .accessibilityLabel(L10n.operationParamDetailLevel)
        }
    }

    private struct AddOperationSummarizeSection: View {
        @ObservedObject var viewModel: AddOperationViewModel
        var body: some View {
            Picker(L10n.operationLabelSummarize, selection: $viewModel.sentenceCountRange) {
                ForEach(SentenceCountRange.allCases, id: \.self) { range in
                    Text(sentenceCountRangeLabel(range)).tag(range)
                        .lineLimit(Common.unlimitedLineLimit)
                        .fixedSize(horizontal: Common.fixedSizeHorizontal, vertical: Common.fixedSizeVertical)
                }
            }
            .pickerStyle(DefaultPickerStyle())
            .accessibilityLabel(L10n.operationLabelSummarize)
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
