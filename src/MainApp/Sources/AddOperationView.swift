import Common
import SwiftUI
#if canImport(ViewInspector)
    import ViewInspector
#endif

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

    public init(viewModel: AddOperationViewModel, onSave: ((InventoryOperation) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSave = onSave
    }

    public var body: some View {
        VStack(spacing: AddOperationViewConstants.verticalSpacing) {
            Text(L10n.addOperationTitle)
                .font(.title2)
                .bold()
                .accessibilityAddTraits(.isHeader)
                .padding(.top, AddOperationViewConstants.topPadding)

            Picker(L10n.addOperationType, selection: $viewModel.selectedKind) {
                ForEach(OperationFactory.allKinds, id: \ .self) { kind in
                    Text(label(for: kind)).tag(Optional(kind))
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(L10n.addOperationType)
            .padding(.horizontal)

            formFields

            colorPalette

            buttons
        }
        .padding()
    }

    @ViewBuilder
    private var formFields: some View {
        switch viewModel.selectedKind {
        case .translate:
            Picker(L10n.operationParamTargetLanguage, selection: $viewModel.targetLanguage) {
                ForEach(supportedLanguages, id: \ .code) { lang in
                    Text(lang.name).tag(lang.code)
                }
            }
            .pickerStyle(.menu)
            .accessibilityLabel(L10n.operationParamTargetLanguage)
            .padding(.horizontal)
        case .simplify:
            Picker(L10n.operationParamComplexityLevel, selection: $viewModel.complexityLevel) {
                Text(L10n.operationValueSchoolchild).tag(ComplexityLevel.schoolchild)
                Text(L10n.operationValueTeenager).tag(ComplexityLevel.teenager)
                Text(L10n.operationValueStudent).tag(ComplexityLevel.student)
                Text(L10n.operationValueAdult).tag(ComplexityLevel.adult)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(L10n.operationParamComplexityLevel)
            .padding(.horizontal)
        case .correct:
            EmptyView()
        case .explain:
            Picker(L10n.operationParamDetailLevel, selection: $viewModel.detailLevel) {
                Text(L10n.operationValueSchoolchild).tag(DetailLevel.schoolchild)
                Text(L10n.operationValueTeenager).tag(DetailLevel.teenager)
                Text(L10n.operationValueStudent).tag(DetailLevel.student)
                Text(L10n.operationValueAdult).tag(DetailLevel.adult)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(L10n.operationParamDetailLevel)
            .padding(.horizontal)
        case .summarize:
            Picker(L10n.operationLabelSummarize, selection: $viewModel.sentenceCountRange) {
                ForEach(SentenceCountRange.allCases, id: \ .self) { range in
                    Text(sentenceCountRangeLabel(range)).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(L10n.operationLabelSummarize)
            .padding(.horizontal)
        case .none:
            EmptyView()
        }
    }

    private var colorPalette: some View {
        VStack(alignment: .leading, spacing: ColorPaletteConstants.verticalSpacing) {
            HStack(spacing: ColorPaletteConstants.circleSpacing) {
                ForEach(AddOperationViewModel.palette, id: \ .self) { hex in
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
        }
        .padding(.horizontal)
        .padding(.bottom, ColorPaletteConstants.bottomPadding)
    }

    private var buttons: some View {
        HStack(spacing: AddOperationViewConstants.verticalSpacing) {
            Button(action: {
                viewModel.cancel()
                dismiss()
            }) {
                Text(L10n.addOperationCancel)
                    .frame(maxWidth: .infinity)
            }
            .accessibilityLabel(L10n.addOperationCancel)
            .buttonStyle(.bordered)

            Button(action: {
                if let op = viewModel.makeOperation() {
                    onSave?(op)
                    dismiss()
                }
            }) {
                Text(L10n.addOperationSave)
                    .frame(maxWidth: .infinity)
            }
            .accessibilityLabel(L10n.addOperationSave)
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isValid)
        }
        .padding(.horizontal)
        .padding(.bottom, AddOperationViewConstants.bottomPadding)
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

    private func sentenceCountRangeLabel(_ range: SentenceCountRange) -> String {
        switch range {
        case .twoToThree: L10n.sentenceCount23
        case .fiveToSix: L10n.sentenceCount56
        case .nineToTen: L10n.sentenceCount910
        }
    }
}
