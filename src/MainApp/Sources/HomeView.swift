import Foundation
import SwiftUI

public struct HomeView: View {
    @ObservedObject public var viewModel: HomeViewModel
    @State private var showAddOperation = false
    @State private var showSettings = false
    @State private var editOperationViewModel: InventoryOperation? = nil
    @State private var editingIndex: Int? = nil
    @Environment(\.colorScheme) private var colorScheme
    @State private var editMode: EditMode = .inactive
    private var palette: MainAppColorPaletteProviding {
        ColorPaletteFactory.palette(for: colorScheme)
    }

    public init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        // Используем ключи, оставленные в ресурсах, чтобы Periphery не помечал их как неиспользуемые
        _ = L10n.homeSortHint
        _ = L10n.homeSortHandle
    }

    public var body: some View {
        NavigationStack {
            operationsList
                .navigationTitle(LocalizedStringKey(L10n.homeTitle))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    bottomBar
                }
        }
        .background(palette.background())
        .environment(\.editMode, $editMode)
        .environment(\.colorPalette, palette)
        .sheet(isPresented: $showAddOperation, onDismiss: {}, content: {
            let addOperationViewModel = AddOperationViewModel(palette: palette.palette())
            AddOperationView(viewModel: addOperationViewModel, onSave: { op in
                viewModel.addOperation(op)
                addOperationViewModel.cancel()
                showAddOperation = false
            })
            .environment(\.colorPalette, palette)
        })
        .sheet(item: $editOperationViewModel, onDismiss: {
            editingIndex = nil
        }, content: { vm in
            EditOperationView(
                viewModel: EditOperationViewModel(operation: vm, palette: palette.palette()),
                onSave: { updatedOperation in
                    if let idx = editingIndex {
                        viewModel.updateOperation(at: idx, with: updatedOperation)
                    }
                    editingIndex = nil
                },
                onDelete: {
                    if let idx = editingIndex {
                        viewModel.removeOperation(at: idx)
                    }
                    editingIndex = nil
                }
            )
            .environment(\.colorPalette, palette)
        })
        .sheet(isPresented: $showSettings, onDismiss: nil, content: {
            SettingsView(viewModel: SettingsViewModel())
                .environment(\.colorPalette, palette)
        })
    }

    private var operationsList: some View {
        List {
            ForEach(Array(viewModel.operations.enumerated()), id: \.element) { idx, operation in
                OperationRowView(
                    operation: operation,
                    palette: palette,
                    isEditing: editMode == .active,
                    onEdit: {
                        editOperationViewModel = operation
                        editingIndex = idx
                    }
                )
                .listRowBackground(palette.background())
            }
            .onMove { indices, newOffset in
                viewModel.reorderOperations(fromOffsets: indices, toOffset: newOffset)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(palette.background())
    }

    private var bottomBar: some View {
        CraftifyButtonBar(backgroundColor: palette.background()) {
            Button(action: { showAddOperation = true }) {
                Label(L10n.homeAddOperation, systemImage: "plus")
                    .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                    .foregroundColor(palette.primaryButtonText())
            }
            .buttonStyle(CraftifyPrimaryButtonStyle())
            Button(action: { showSettings = true }) {
                Label(L10n.homeSettings, systemImage: "gearshape")
                    .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                    .foregroundColor(palette.secondaryButtonText())
            }
            .buttonStyle(CraftifySecondaryButtonStyle())
        }
    }

    private struct OperationRowView: View {
        let operation: InventoryOperation
        let palette: MainAppColorPaletteProviding
        let isEditing: Bool
        let onEdit: () -> Void

        private static let circleSize: CGFloat = 28
        private static let symbolScale: CGFloat = 0.5

        var body: some View {
            Button(action: onEdit) {
                Label {
                    HStack {
                        OperationLabelText(type: operation.operation)
                        Spacer()
                        OperationParamsText(operation: operation)
                    }
                } icon: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: operation.colorHex))
                            .frame(width: Self.circleSize, height: Self.circleSize)
                            .accessibilityHidden(true)
                        Image(systemName: operation.operation.sfSymbol)
                            .foregroundColor(palette.operationSymbolColor())
                            .font(.system(size: Self.circleSize * Self.symbolScale))
                            .fontWeight(.semibold)
                            .accessibilityLabel(LocalizedStringKey(operationLabel(for: operation.operation)))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isEditing)
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
                .foregroundColor(Color.secondary)
        }

        private func operationParamsDescription(for operation: InventoryOperation) -> String {
            switch operation.operation {
            case .translate:
                if let params = try? JSONDecoder().decode(TranslateParams.self, from: operation.params) {
                    return "\u{2192} \(params.targetLanguage)"
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
                    return params.length
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
    }
}
