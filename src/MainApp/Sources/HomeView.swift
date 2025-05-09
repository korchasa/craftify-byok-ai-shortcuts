import Foundation
import SwiftUI

public struct HomeView: View {
    @ObservedObject public var viewModel: HomeViewModel
    @State private var showAddOperation = false
    @State private var showSettings = false
    @State private var showEditOperation = false
    @State private var editOperationViewModel: InventoryOperation? = nil
    @State private var editingIndex: Int? = nil
    @Environment(\.colorScheme) private var colorScheme
    private var palette: MainAppColorPaletteProviding {
        ColorPaletteFactory.palette(for: colorScheme)
    }

    public init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationView {
            CommonFormContainer(
                title: LocalizedStringKey(L10n.homeTitle),
                content: {
                    operationsList
                },
                buttons: {
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
            )
        }
        .background(palette.background())
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
        VStack(spacing: 0) {
            operationsListContent
        }
    }

    private var operationsListContent: some View {
        List {
            ForEach(Array(viewModel.operations.enumerated()), id: \ .element) { idx, operation in
                OperationRowView(
                    operation: operation,
                    palette: palette,
                    onEdit: {
                        editOperationViewModel = operation
                        editingIndex = idx
                    },
                    onDelete: {}
                )
                .buttonStyle(PlainButtonStyle())
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(palette.background())
            }
            .onMove { indices, newOffset in
                viewModel.reorderOperations(fromOffsets: indices, toOffset: newOffset)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(palette.background())
        .environment(\.editMode, .constant(.active))
    }

    private struct OperationRowView: View {
        let operation: InventoryOperation
        let palette: MainAppColorPaletteProviding
        let onEdit: () -> Void
        let onDelete: () -> Void
        private static let iconToLabelSpacing: CGFloat = 12

        var body: some View {
            Button(action: onEdit) {
                HStack(spacing: 0) {
                    OperationIconCircle(kind: operation.operation, colorHex: operation.colorHex, palette: palette)
                        .padding(.trailing, Self.iconToLabelSpacing)
                    OperationLabelText(type: operation.operation)
                    Spacer()
                    OperationParamsText(operation: operation, palette: palette)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private struct OperationIconCircle: View {
        let kind: OperationKind
        let colorHex: String
        let palette: MainAppColorPaletteProviding
        private static let symbolScale: CGFloat = 0.5
        var body: some View {
            ZStack {
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: palette.circleSize, height: palette.circleSize)
                    .accessibilityLabel("Цвет операции")
                Image(systemName: kind.sfSymbol)
                    .foregroundColor(palette.primaryButtonText())
                    .font(.system(size: palette.circleSize * OperationIconCircle.symbolScale))
                    .fontWeight(.semibold)
                    .accessibilityLabel("SF Symbol for operation: \(kind.rawValue)")
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
        let palette: MainAppColorPaletteProviding
        var body: some View {
            Text(operationParamsDescription(for: operation))
                .font(.craftifyFootnote)
                .fontWeight(.semibold)
                .foregroundColor(palette.secondaryText())
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
