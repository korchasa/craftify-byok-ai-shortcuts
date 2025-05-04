import Common
import SwiftUI

public struct EditOperationView: View {
    @ObservedObject public var viewModel: EditOperationViewModel
    private let onSave: (InventoryOperation) -> Void
    @Environment(\.dismiss) private var dismiss

    private let supportedLanguages: [(name: String, code: String)] = [
        ("български", "bg"),
        ("deutsch", "de"),
        ("english", "en"),
        ("español", "es"),
        ("français", "fr"),
        ("日本語", "ja"),
        ("русский", "ru"),
        ("українська", "uk"),
        ("中文", "zh")
    ]

    private let colorPaletteVerticalPadding: CGFloat = 8

    public init(viewModel: EditOperationViewModel, onSave: @escaping (InventoryOperation) -> Void) {
        self.viewModel = viewModel
        self.onSave = onSave
    }

    public var body: some View {
        Form {
            Section(header: Text(L10n.addOperationType).font(.craftifyTitle).fontWeight(.bold)) {
                EditOperationTypeSection(viewModel: viewModel)
            }
            Section {
                EditOperationFields(viewModel: viewModel)
            }
            Section(header: Text(L10n.color).font(.craftifyTitle).fontWeight(.bold)) {
                EditOperationColorPalette(viewModel: viewModel)
            }
            Section {
                EditOperationButtons(viewModel: viewModel, onSave: onSave, dismiss: dismiss)
            }
        }
        .background(Color.white)
        .navigationTitle(LocalizedStringKey(L10n.editOperationTitle))
        .formStyle(.grouped)
    }

    private struct EditOperationButtons: View {
        @ObservedObject var viewModel: EditOperationViewModel
        var onSave: (InventoryOperation) -> Void
        var dismiss: DismissAction
        var body: some View {
            HStack(spacing: MainAppButtonConstants.horizontalPadding) {
                Button(action: {
                    viewModel.cancel()
                    dismiss()
                }) {
                    Label(L10n.editOperationCancel, systemImage: "xmark")
                        .font(.craftifyBody)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .buttonStyle(CraftifySecondaryButtonStyle())
                .accessibilityLabel(L10n.editOperationCancel)
                Button(action: {
                    if let op = viewModel.makeOperation() {
                        onSave(op)
                        dismiss()
                    }
                }) {
                    Label(L10n.editOperationSave, systemImage: "checkmark")
                        .font(.craftifyBody)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .buttonStyle(CraftifyPrimaryButtonStyle())
                .accessibilityLabel(L10n.editOperationSave)
                .disabled(!viewModel.isValid)
            }
            .padding(.horizontal, MainAppButtonConstants.horizontalPadding)
            .padding(.bottom, MainAppButtonConstants.bottomPadding)
            .background(Color.white.ignoresSafeArea())
            .cornerRadius(MainAppButtonConstants.cornerRadius)
        }
    }

    private struct EditOperationTypeSection: View {
        @ObservedObject var viewModel: EditOperationViewModel
        var body: some View {
            Picker(L10n.addOperationType, selection: $viewModel.selectedKind) {
                ForEach(OperationFactory.allKinds, id: \.self) { kind in
                    Text(label(for: kind)).tag(Optional(kind))
                }
            }
            .pickerStyle(DefaultPickerStyle())
            .accessibilityLabel(L10n.addOperationType)
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
            Picker(L10n.operationParamTargetLanguage, selection: $viewModel.targetLanguage) {
                ForEach(viewModel.supportedLanguages, id: \ .code) { lang in
                    Text(lang.name).tag(lang.code)
                }
            }
            .pickerStyle(DefaultPickerStyle())
            .accessibilityLabel(L10n.operationParamTargetLanguage)
        }
    }

    private struct EditOperationSimplifySection: View {
        @ObservedObject var viewModel: EditOperationViewModel
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

    private struct EditOperationExplainSection: View {
        @ObservedObject var viewModel: EditOperationViewModel
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

    private struct EditOperationSummarizeSection: View {
        @ObservedObject var viewModel: EditOperationViewModel
        var body: some View {
            Picker(L10n.operationLabelSummarize, selection: $viewModel.sentenceCountRange) {
                ForEach(SentenceCountRange.allCases, id: \ .self) { range in
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

    private struct EditOperationColorPalette: View {
        @ObservedObject var viewModel: EditOperationViewModel
        private static let verticalPadding: CGFloat = 8
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ColorPaletteConstants.circleSpacing) {
                    ForEach(EditOperationViewModel.palette, id: \ .self) { hex in
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
                .padding(.vertical, Self.verticalPadding)
            }
        }
    }
}
