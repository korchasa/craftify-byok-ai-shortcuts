import Foundation
import os
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

    /// Диагностика полевого iPad-бага: шит настроек закрывался при тапе по строке модели
    fileprivate static let uiLog = OSLog(subsystem: "Internal", category: "SettingsUI")

    public init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        // Используем ключи, оставленные в ресурсах, чтобы Periphery не помечал их как неиспользуемые
        _ = L10n.homeSortHint
        _ = L10n.homeSortHandle
        _ = L10n.homeOrder
    }

    public var body: some View {
        NavigationStack {
            operationsList
                // Собственная шапка вместо системного навбара: кнопка Edit должна
                // стоять в строке заголовка, а не липнуть к верхней кромке окна
                // (заметно в оконном режиме iPad)
                .safeAreaInset(edge: .top) {
                    titleBar
                }
                .toolbar(.hidden, for: .navigationBar)
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
        .sheet(
            item: $editOperationViewModel,
            onDismiss: {
                editingIndex = nil
            },
            content: { vm in
                EditOperationView(
                    viewModel: EditOperationViewModel(operation: vm, palette: palette.palette()),
                    onSave: { updatedOperation in
                        if let idx = editingIndex {
                            viewModel.updateOperation(at: idx, with: updatedOperation)
                        }
                        editingIndex = nil
                    }
                )
                .environment(\.colorPalette, palette)
            }
        )
        .sheet(isPresented: $showSettings, onDismiss: nil, content: {
            SettingsView(viewModel: SettingsViewModel())
                .environment(\.colorPalette, palette)
                // Настройки закрываются только кнопками: в форме бывает несохранённый
                // ключ, а на iPad жест/клик мимо шита молча уносил ввод
                .interactiveDismissDisabled()
        })
        .onChange(of: showSettings) { newValue in
            os_log("%{public}@", log: HomeView.uiLog, type: .info, "showSettings changed: \(newValue)")
        }
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
            .onDelete { indices in
                for index in indices {
                    viewModel.removeOperation(at: index)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(palette.background())
    }

    /// Строка заголовка: крупный титул слева, Edit — на той же линии справа
    private var titleBar: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(LocalizedStringKey(L10n.homeTitle))
                .font(.largeTitle)
                .fontWeight(.bold)
            Spacer()
            EditButton()
                .font(.craftifyBody)
        }
        .padding(.horizontal, FormStyleConstants.titleBarHorizontalPadding)
        .padding(.top, FormStyleConstants.sectionSpacing)
        .padding(.bottom, FormStyleConstants.dividerBottomPadding)
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
            .buttonStyle(SettingsPrimaryButtonStyle())
            .accessibilityIdentifier("home_settings_button")
        }
    }

    private struct OperationRowView: View {
        let operation: InventoryOperation
        let palette: MainAppColorPaletteProviding
        let isEditing: Bool
        let onEdit: () -> Void

        private static let baseCircleUnscaled: CGFloat = 28
        private static let baseCircleSize: CGFloat = baseCircleUnscaled * DeviceScale.controlFactor
        private static let symbolScale: CGFloat = 0.5
        private static let horizontalSpacing: CGFloat = 12
        /// Кружок операции масштабируется вместе с системным размером шрифта
        @ScaledMetric(relativeTo: .body) private var circleSize: CGFloat = Self.baseCircleSize

        var body: some View {
            Button(action: onEdit) {
                HStack(spacing: Self.horizontalSpacing) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: operation.colorHex))
                            .frame(width: circleSize, height: circleSize)
                            .accessibilityHidden(true)
                        Image(systemName: operation.operation.sfSymbol)
                            .foregroundColor(palette.operationSymbolColor())
                            .font(.system(size: circleSize * Self.symbolScale))
                            .fontWeight(.semibold)
                            .accessibilityLabel(LocalizedStringKey(operationLabel(for: operation.operation)))
                    }
                    OperationLabelText(type: operation.operation)
                    Spacer()
                    OperationParamsText(operation: operation)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isEditing)
            .accessibilityIdentifier("operation_row_\(operation.operation.rawValue)")
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
                    let langName = SupportedLanguages.all.first { $0.code == params.targetLanguage }?.name ?? params.targetLanguage
                    return "\u{2192} " + langName
                }
            case .simplify:
                return ""
            case .correct:
                return ""
            case .explain:
                return ""
            case .summarize:
                if let params = try? JSONDecoder().decode(SummarizeParams.self, from: operation.params) {
                    return SummarizeLengthDisplay.label(for: params.length)
                }
            }
            return ""
        }
    }
}
