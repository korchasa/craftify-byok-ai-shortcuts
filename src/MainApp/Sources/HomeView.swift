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
            EditOperationView(viewModel: vm, onSave: { updatedOperation in
                if let idx = editingIndex {
                    viewModel.updateOperation(at: idx, with: updatedOperation)
                }
                editingIndex = nil
            })
        })
        .sheet(isPresented: $showSettings, onDismiss: nil, content: {
            SettingsView(viewModel: SettingsViewModel())
        })
    }

    private var operationsList: some View {
        List {
            ForEach(Array(viewModel.operations.enumerated()), id: \ .element) { idx, operation in
                OperationRowView(
                    operation: operation,
                    onEdit: {
                        editOperationViewModel = EditOperationViewModel(operation: operation)
                        editingIndex = idx
                    },
                    onDelete: {
                        viewModel.removeOperation(at: idx)
                    }
                )
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

    private struct OperationRowView: View {
        let operation: InventoryOperation
        let onEdit: () -> Void
        let onDelete: () -> Void

        var body: some View {
            HStack {
                Circle()
                    .fill(Color(hex: operation.colorHex))
                    .frame(width: ColorPaletteConstants.circleSize, height: ColorPaletteConstants.circleSize)
                    .accessibilityLabel("Цвет операции")
                Text(operationLabel(for: operation.operation))
                    .font(.headline)
                Spacer()
                Text(operationParamsDescription(for: operation))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .swipeActions(edge: .trailing) {
                Button {
                    onEdit()
                } label: {
                    Text(L10n.homeEdit)
                }
                .tint(.blue)
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Text(L10n.homeDelete)
                }
                .tint(.red)
            }
        }

        private func operationLabel(for type: OperationKind) -> String {
            switch type {
            case .translate: L10n.operationLabelTranslate
            case .simplify: L10n.operationLabelSimplify
            case .correct: L10n.operationLabelCorrect
            case .explain: L10n.operationLabelExplain
            case .summarize: L10n.operationLabelSummarize
            }
        }

        private func operationParamsDescription(for operation: InventoryOperation) -> String {
            switch operation.operation {
            case .translate:
                if let params = try? JSONDecoder().decode(TranslateParams.self, from: operation.params) {
                    return "→ \(params.targetLanguage)"
                }
            case .simplify:
                if let params = try? JSONDecoder().decode(SimplifyParams.self, from: operation.params) {
                    return labelForComplexityLevel(params.complexityLevel)
                }
            case .correct:
                return ""
            case .explain:
                if let params = try? JSONDecoder().decode(ExplainParams.self, from: operation.params) {
                    return labelForDetailLevel(params.detailLevel)
                }
            case .summarize:
                if let params = try? JSONDecoder().decode(SummarizeParams.self, from: operation.params) {
                    return sentenceCountRangeLabel(params.sentenceCountRange)
                }
            }
            return ""
        }

        private func labelForComplexityLevel(_ level: ComplexityLevel) -> String {
            switch level {
            case .schoolchild: L10n.operationValueSchoolchild
            case .teenager: L10n.operationValueTeenager
            case .student: L10n.operationValueStudent
            case .adult: L10n.operationValueAdult
            }
        }

        private func labelForDetailLevel(_ level: DetailLevel) -> String {
            switch level {
            case .schoolchild: L10n.operationValueSchoolchild
            case .teenager: L10n.operationValueTeenager
            case .student: L10n.operationValueStudent
            case .adult: L10n.operationValueAdult
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
}
