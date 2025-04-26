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

            Picker(L10n.addOperationType, selection: $viewModel.selectedType) {
                Text(L10n.operationLabelTranslate).tag(OperationType?.some(.translate))
                Text(L10n.operationLabelSimplify).tag(OperationType?.some(.simplify))
                Text(L10n.operationLabelCorrect).tag(OperationType?.some(.correct))
                Text(L10n.operationLabelExplain).tag(OperationType?.some(.explain))
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(L10n.addOperationType)
            .padding(.horizontal)

            formFields

            buttons
        }
        .padding()
    }

    @ViewBuilder
    private var formFields: some View {
        switch viewModel.selectedType {
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
                Text(L10n.operationValueBeginner).tag(ComplexityLevel.beginner)
                Text(L10n.operationValueIntermediate).tag(ComplexityLevel.intermediate)
                Text(L10n.operationValueAdvanced).tag(ComplexityLevel.advanced)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(L10n.operationParamComplexityLevel)
            .padding(.horizontal)
        case .correct:
            Stepper(value: $viewModel.stylePreservationLevel, in: AddOperationViewConstants.styleMin ... AddOperationViewConstants.styleMax) {
                Text("\(L10n.operationParamStylePreservation): \(viewModel.stylePreservationLevel)/\(AddOperationViewConstants.styleMax)")
            }
            .accessibilityLabel(L10n.operationParamStylePreservation)
            .padding(.horizontal)
        case .explain:
            Picker(L10n.operationParamDetailLevel, selection: $viewModel.detailLevel) {
                Text(L10n.operationValueBeginner).tag(DetailLevel.beginner)
                Text(L10n.operationValueIntermediate).tag(DetailLevel.intermediate)
                Text(L10n.operationValueAdvanced).tag(DetailLevel.advanced)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel(L10n.operationParamDetailLevel)
            .padding(.horizontal)
        case .none:
            EmptyView()
        }
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
}
