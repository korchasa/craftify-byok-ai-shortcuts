import Common
import SwiftUI

#if canImport(ViewInspector)
    // moved to EditOperationView+Inspectable.swift
#endif

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

    public init(viewModel: EditOperationViewModel, onSave: @escaping (InventoryOperation) -> Void) {
        self.viewModel = viewModel
        self.onSave = onSave
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

            colorPalette

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

    private var colorPalette: some View {
        VStack(alignment: .leading, spacing: ColorPaletteConstants.verticalSpacing) {
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
                Text(L10n.editOperationCancel)
                    .frame(maxWidth: .infinity)
            }
            .accessibilityLabel(L10n.editOperationCancel)
            .buttonStyle(.bordered)

            Button(action: {
                if let op = viewModel.makeOperation() {
                    onSave(op)
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
