import Common
import SwiftUI

public struct HomeView: View {
    @ObservedObject public var viewModel: HomeViewModel
    @State private var showAddOperation = false
    @State private var showSettings = false
    @State private var addOperationViewModel = AddOperationViewModel()
    @State private var showEditOperation = false
    @State private var editOperationViewModel: EditOperationViewModel? = nil
    @State private var editingIndex: Int? = nil

    public init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationView {
            VStack {
                operationsList
                HStack {
                    Button(action: { showAddOperation = true }) {
                        Text(L10n.homeAddOperation)
                    }
                    .accessibilityLabel(L10n.homeAddOperation)
                    Spacer()
                    Button(action: { showSettings = true }) {
                        Text(L10n.homeSettings)
                    }
                    .accessibilityLabel(L10n.homeSettings)
                }
                .padding()
            }
            .navigationTitle(L10n.homeTitle)
        }
        .sheet(isPresented: $showAddOperation, onDismiss: { addOperationViewModel.cancel() }, content: {
            AddOperationView(viewModel: addOperationViewModel, onSave: { op in
                viewModel.addOperation(op)
                addOperationViewModel.cancel()
                showAddOperation = false
            })
        })
        .sheet(item: $editOperationViewModel, onDismiss: {
            editingIndex = nil
        }, content: { vm in
            EditOperationView(viewModel: vm)
                .onDisappear {
                    if let idx = editingIndex, let updated = vm.makeOperation() {
                        viewModel.updateOperation(at: idx, with: updated)
                    }
                    editingIndex = nil
                }
        })
        .sheet(isPresented: $showSettings, onDismiss: nil, content: {
            SettingsView(viewModel: SettingsViewModel())
        })
    }

    private var operationsList: some View {
        List {
            ForEach(Array(viewModel.operations.enumerated()), id: \ .element) { idx, operation in
                HStack {
                    Text(operationLabel(for: operation.operation))
                        .font(.headline)
                    Spacer()
                    Text(operationParamsDescription(for: operation))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        editOperationViewModel = EditOperationViewModel(operation: operation)
                        editingIndex = idx
                    } label: {
                        Text(L10n.homeEdit)
                    }
                    .tint(.blue)
                }
            }
            .onDelete { indices in
                for index in indices {
                    viewModel.removeOperation(at: index)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private let settingsSheet: AnyView = .init(Text("SettingsView"))

    private func operationLabel(for type: OperationType) -> String {
        switch type {
        case .translate: "Перевод"
        case .simplify: "Упрощение"
        case .correct: "Коррекция"
        case .explain: "Объяснение"
        }
    }

    private func operationParamsDescription(for operation: InventoryOperation) -> String {
        switch operation.operation {
        case .translate:
            if let params = try? JSONDecoder().decode(TranslateParams.self, from: operation.params) {
                return "Язык: → \(params.targetLanguage)"
            }
        case .simplify:
            if let params = try? JSONDecoder().decode(SimplifyParams.self, from: operation.params) {
                return "Уровень: \(params.complexityLevel.rawValue)"
            }
        case .correct:
            if let params = try? JSONDecoder().decode(CorrectParams.self, from: operation.params) {
                return "Сохранение стиля: \(params.stylePreservationLevel)/3"
            }
        case .explain:
            if let params = try? JSONDecoder().decode(ExplainParams.self, from: operation.params) {
                return "Детализация: \(params.detailLevel.rawValue)"
            }
        }
        return ""
    }
}
