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
                Spacer()
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: MainAppButtonConstants.horizontalPadding) {
                    Button(action: { showAddOperation = true }) {
                        Label(L10n.homeAddOperation, systemImage: "plus")
                            .font(.craftifyBody)
                            .fontWeight(.bold)
                    }
                    .accessibilityLabel(L10n.homeAddOperation)
                    .buttonStyle(CraftifyPrimaryButtonStyle())
                    Button(action: { showSettings = true }) {
                        Label(L10n.homeSettings, systemImage: "gearshape")
                            .font(.craftifyBody)
                            .fontWeight(.bold)
                    }
                    .accessibilityLabel(L10n.homeSettings)
                    .buttonStyle(CraftifySecondaryButtonStyle())
                }
                .padding(.horizontal, MainAppButtonConstants.horizontalPadding)
                .padding(.bottom, MainAppButtonConstants.bottomPadding)
                .background(Color.white.ignoresSafeArea())
                .cornerRadius(MainAppButtonConstants.cornerRadius)
            }
            .navigationTitle(L10n.homeTitle)
            .font(.craftifyTitle)
            .fontWeight(.bold)
        }
        .background(Color.white)
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
        .listStyle(.plain)
        .background(Color.white)
    }

    private let settingsSheet: AnyView = .init(Text("SettingsView"))

    private struct OperationRowView: View {
        let operation: InventoryOperation
        let onEdit: () -> Void
        let onDelete: () -> Void

        var body: some View {
            HStack {
                OperationColorCircle(colorHex: operation.colorHex)
                OperationLabelText(type: operation.operation)
                Spacer()
                OperationParamsText(operation: operation)
            }
            .swipeActions(edge: .trailing) {
                OperationEditButton(onEdit: onEdit)
                OperationDeleteButton(onDelete: onDelete)
            }
        }
    }

    private struct OperationColorCircle: View {
        let colorHex: String
        var body: some View {
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: ColorPaletteConstants.circleSize, height: ColorPaletteConstants.circleSize)
                .accessibilityLabel("Цвет операции")
        }
    }

    private struct OperationLabelText: View {
        let type: OperationKind
        var body: some View {
            Text(operationLabel(for: type))
                .font(.craftifyBody)
                .fontWeight(.semibold)
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
    }

    private struct OperationParamsText: View {
        let operation: InventoryOperation
        var body: some View {
            Text(operationParamsDescription(for: operation))
                .font(.craftifyFootnote)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
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

    private struct OperationEditButton: View {
        let onEdit: () -> Void
        var body: some View {
            Button {
                onEdit()
            } label: {
                Text(L10n.homeEdit)
                    .font(.craftifyBody)
                    .fontWeight(.bold)
            }
            .tint(.blue)
        }
    }

    private struct OperationDeleteButton: View {
        let onDelete: () -> Void
        var body: some View {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Text(L10n.homeDelete)
                    .font(.craftifyBody)
                    .fontWeight(.bold)
            }
            .tint(.red)
        }
    }
}
