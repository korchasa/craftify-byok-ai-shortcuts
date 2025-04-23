import CraftifyShared
import SwiftUI
#if canImport(ViewInspector)
    import ViewInspector
#endif

public struct AddOperationView: View {
    @ObservedObject public var viewModel: AddOperationViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: AddOperationViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: AddOperationViewConstants.verticalSpacing) {
            Text(L10n.addOperationTitle)
                .font(.title2)
                .bold()
                .accessibilityAddTraits(.isHeader)
                .padding(.top, AddOperationViewConstants.topPadding)

            Picker(L10n.addOperationType, selection: $viewModel.selectedType) {
                Text("Перевод").tag(OperationType?.some(.translate))
                Text("Упрощение").tag(OperationType?.some(.simplify))
                Text("Коррекция").tag(OperationType?.some(.correct))
                Text("Объяснение").tag(OperationType?.some(.explain))
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
            TextField("Язык перевода", text: $viewModel.targetLanguage)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Язык перевода")
                .padding(.horizontal)
        case .simplify:
            Picker("Уровень сложности", selection: $viewModel.complexityLevel) {
                Text("Школьник").tag(ComplexityLevel.beginner)
                Text("Студент").tag(ComplexityLevel.intermediate)
                Text("Эксперт").tag(ComplexityLevel.advanced)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Уровень сложности")
            .padding(.horizontal)
        case .correct:
            Stepper(value: $viewModel.stylePreservationLevel, in: AddOperationViewConstants.styleMin ... AddOperationViewConstants.styleMax) {
                Text("Сохранение стиля: \(viewModel.stylePreservationLevel)/\(AddOperationViewConstants.styleMax)")
            }
            .accessibilityLabel("Сохранение стиля")
            .padding(.horizontal)
        case .explain:
            Picker("Детализация", selection: $viewModel.detailLevel) {
                Text("Школьник").tag(DetailLevel.beginner)
                Text("Студент").tag(DetailLevel.intermediate)
                Text("Эксперт").tag(DetailLevel.advanced)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Детализация")
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
                if let _ = viewModel.makeOperation() {
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
