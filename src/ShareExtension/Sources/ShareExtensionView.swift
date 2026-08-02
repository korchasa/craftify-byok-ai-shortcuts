import Foundation
import SwiftUI

public struct ShareExtensionView: View {
    @ObservedObject public var viewModel: ShareExtensionViewModel
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isProcessing = false
    @Environment(\.colorScheme) private var colorScheme
    private var palette: ShareExtensionColorPaletteProviding {
        ShareExtensionColorPaletteFactory.palette(for: colorScheme)
    }

    private enum ZIndexConstants {
        static let overlay: Double = 2
    }

    public init(viewModel: ShareExtensionViewModel) {
        self.viewModel = viewModel
    }

    // [REF:fr:ux.share-input-preview]
    /// Текст, над которым работаем. Лежит на подложке — слоем ниже карточки
    /// с операциями, поэтому места ему столько, сколько осталось над карточкой
    @ViewBuilder
    private var inputPreview: some View {
        if viewModel.inputText.isEmpty {
            Text(L10n.shareTitle)
                .font(.craftifyTitle)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: ShareExtensionViewConstants.inputPreviewSpacing) {
                Text(viewModel.isInputURL ? L10n.shareInputCaptionLink : L10n.shareInputCaption)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .kerning(ShareExtensionViewConstants.inputPreviewCaptionKerning)
                    .foregroundColor(palette.secondaryText())
                    .accessibilityAddTraits(.isHeader)
                Text(viewModel.inputText)
                    .font(.craftifyBody)
                    .fontWeight(.regular)
                    .foregroundColor(palette.primaryText())
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Верхний слой: текст на подложке. Длинный текст не обрезается —
    /// он прокручивается в оставшемся над карточкой месте
    private var inputArea: some View {
        ScrollView {
            inputPreview
                .padding(.horizontal, FormStyleConstants.titleBarHorizontalPadding)
                .padding(.top, ShareExtensionViewConstants.topPadding)
                .padding(.bottom, ShareExtensionViewConstants.inputPreviewBottomSpacing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// Карточка с операциями и кнопками. Прижата к низу, как сетка и
    /// «Настройки» на главном экране: свободное место остаётся тексту сверху
    private var card: some View {
        VStack(spacing: 0) {
            if viewModel.displayResult != nil {
                resultArea
            } else {
                operationsGrid
                    .padding(.top, ShareExtensionViewConstants.topPadding)
            }
            buttonRow
        }
        .frame(maxWidth: .infinity, maxHeight: viewModel.displayResult != nil ? .infinity : nil)
        .background(
            palette.background()
                .clipShape(TopRoundedShape(radius: ShareExtensionViewConstants.cardCornerRadius))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    /// Результат обработки занимает карточку целиком и прокручивается
    private var resultArea: some View {
        VStack(spacing: ShareExtensionViewConstants.verticalSpacing) {
            Text(displayOperationTitle())
                .font(.craftifyTitle)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, ShareExtensionViewConstants.topPadding)
            ScrollView {
                DisplayResultView(text: viewModel.displayResult ?? "")
            }
        }
        .padding(.horizontal, FormStyleConstants.titleBarHorizontalPadding)
    }

    /// Кнопки под сеткой: закрытие всегда, копирование — когда есть результат
    private var buttonRow: some View {
        HStack(spacing: CraftifyButtonConstants.horizontalPadding) {
            closeButton
            if viewModel.displayResult != nil {
                copyAndCloseButton
            }
        }
        .padding(.horizontal, FormStyleConstants.titleBarHorizontalPadding)
        .padding(.top, FormStyleConstants.sectionSpacing)
        .padding(.bottom, FormStyleConstants.bottomPadding)
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Результат разворачивает карточку на весь экран — текст,
                // над которым работали, уже не нужен
                if viewModel.displayResult == nil {
                    inputArea
                }
                card
            }
            // Processing overlay
            if isProcessing {
                progressOverlay
            }
        }
        .background(palette.backdrop().ignoresSafeArea())
        .zIndex(ZIndexConstants.overlay)
        // Крупные размеры ограничиваем, чтобы сетка 2xN оставалась пригодной
        .dynamicTypeSize(.xSmall ... .accessibility3)
        .environment(\.shareExtensionColorPalette, palette)
        // ViewModel subscriptions & alerts
        .onReceive(viewModel.$errorMessage) { msg in
            if let msg, !showAlert {
                viewModel.manager.logManager.log(LogEntry(
                    level: .error,
                    module: "ShareExtensionView",
                    message: "Presenting alert with message: \(msg)",
                    metadata: [:],
                    timestamp: Date()
                ))
                alertMessage = msg
                showAlert = true
            }
        }
        .onReceive(viewModel.$isProcessing) { isProcessing = $0 }
        .onReceive(viewModel.$shouldCloseExtension) { shouldClose in
            if shouldClose {
                NotificationCenter.default.post(name: .closeShareExtension, object: nil)
            }
        }
        .alert(isPresented: $showAlert) {
            errorAlert
        }
    }

    /// Для транзиентных ошибок алерт предлагает повтор без повторного выбора операции
    private var errorAlert: Alert {
        if viewModel.isLastErrorRetryable {
            return Alert(
                title: Text(L10n.error),
                message: Text(alertMessage),
                primaryButton: .default(Text(L10n.retry)) {
                    alertMessage = ""
                    viewModel.retry()
                },
                secondaryButton: .cancel(Text(LocalizedStringKey("OK"))) {
                    alertMessage = ""
                    viewModel.dismissError()
                }
            )
        }
        return Alert(
            title: Text(L10n.error),
            message: Text(alertMessage),
            dismissButton: .default(Text(LocalizedStringKey("OK"))) {
                alertMessage = ""
                viewModel.dismissError()
            }
        )
    }

    /// Сетка повторяет раскладку главного экрана вместе с дырками: пользователь
    /// расставил плитки в приложении, чтобы узнавать их здесь по месту.
    /// Целиком пустые ряды выбрасываем: подходящих входу операций бывает
    /// меньше, чем плиток, и такие ряды оставляли бы дыру над кнопкой
    private var operationsGrid: some View {
        let cells = OperationGrid.withoutEmptyRows(
            OperationGrid.cells(for: viewModel.operations, minimumCells: 0),
            columns: OperationTileConstants.columns
        )
        return LazyVGrid(columns: OperationGridLayout.columns, spacing: OperationTileConstants.gridSpacing) {
            ForEach(OperationGrid.displayOrder(cells, columns: OperationTileConstants.columns), id: \.slot) { cell in
                if let operation = cell.operation {
                    operationButton(for: operation)
                } else {
                    Color.clear
                        .frame(height: OperationTileConstants.height)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.horizontal, FormStyleConstants.titleBarHorizontalPadding)
    }

    /// Плитка операции — та же, что пользователь расставил на главном экране
    private func operationButton(for op: InventoryOperation) -> some View {
        let tile = OperationTileView(
            operation: op,
            symbolColor: palette.operationSymbolColor(),
            textColor: palette.primaryButtonText()
        )
        return Button(action: { viewModel.process(operation: op) }) { tile }
            .accessibilityLabel(tile.accessibilityText)
            .disabled(viewModel.isProcessing)
    }

    private var progressOverlay: some View {
        VStack(spacing: ShareExtensionViewConstants.verticalSpacing) {
            ProgressView()
                .progressViewStyle(.circular)
            Text(stageText)
                .font(.craftifyBody)
                .fontWeight(.semibold)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: ShareExtensionViewConstants.overlayCornerRadius).fill(Color(.systemBackground).opacity(ShareExtensionViewConstants.overlayOpacity)))
        .shadow(radius: ShareExtensionViewConstants.overlayShadow)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stageText)
    }

    /// Локализованный текст текущей стадии обработки
    private var stageText: String {
        switch viewModel.stage {
        case .fetchingPage: L10n.progressLoadingPage
        case .askingModel: L10n.progressAskingModel
        case nil: L10n.processing
        }
    }

    /// Возвращает локализованное название текущей операции для заголовка окна
    private func displayOperationTitle() -> String {
        guard let op = viewModel.operations.first(where: { viewModel.displayResult != nil && $0.operation == viewModel.manager.lastOperationKind }) else {
            return L10n.shareTitle
        }
        return OperationDisplay.title(for: op.operation)
    }

    /// View для отображения результата и кнопки закрытия
    private struct DisplayResultView: View {
        let text: String
        var body: some View {
            MarkdownLLMView(markdown: text)
        }
    }

    /// Закрытие оформлено как «Настройки» на главном экране: плоская строка
    /// без заливки, чтобы не спорить с плитками
    private var closeButton: some View {
        Button(action: { viewModel.shouldCloseExtension = true }) {
            Label(L10n.shareCancel, systemImage: "xmark")
                .font(.craftifyBody)
                .fontWeight(.semibold)
                .foregroundColor(palette.primaryText())
                .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var copyAndCloseButton: some View {
        Button(action: { viewModel.copyDisplayedResultAndClose() }) {
            Label(L10n.shareCopyClose, systemImage: "doc.on.doc")
                .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                .foregroundColor(palette.primaryButtonText())
        }
        .buttonStyle(ShareExtensionPrimaryButtonStyle())
    }
}
