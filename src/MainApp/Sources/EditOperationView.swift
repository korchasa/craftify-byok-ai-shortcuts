import CraftifyShared
import SwiftUI

#if canImport(ViewInspector)
    // moved to EditOperationView+Inspectable.swift
#endif

public struct EditOperationView: View {
    @ObservedObject public var viewModel: EditOperationViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: EditOperationViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: AddOperationViewConstants.verticalSpacing) {
            Text(L10n.editOperationTitle)
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
            .disabled(true) // нельзя менять тип операции при редактировании

            formFields

            buttons
        }
        .padding()
    }

    @ViewBuilder
    private var formFields: some View {
        switch viewModel.selectedType {
        case .translate:
            TextField(L10n.operationParamTargetLanguage, text: $viewModel.targetLanguage)
                .textFieldStyle(.roundedBorder)
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
            Stepper(value: $viewModel.stylePreservationLevel, in: EditOperationViewModel.minStylePreservationLevel ... EditOperationViewModel.maxStylePreservationLevel) {
                Text("\(L10n.operationParamStylePreservation): \(viewModel.stylePreservationLevel)/\(EditOperationViewModel.maxStylePreservationLevel)")
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
                Text(L10n.editOperationCancel)
                    .frame(maxWidth: .infinity)
            }
            .accessibilityLabel(L10n.editOperationCancel)
            .buttonStyle(.bordered)

            Button(action: {
                if let _ = viewModel.makeOperation() {
                    dismiss()
                }
            }) {
                Text(L10n.editOperationSave)
                    .frame(maxWidth: .infinity)
            }
            .accessibilityLabel(L10n.editOperationSave)
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isValid)
        }
        .padding(.horizontal)
        .padding(.bottom, AddOperationViewConstants.bottomPadding)
    }
}

#if canImport(ViewInspector)
    // moved to EditOperationView+Inspectable.swift
#endif
