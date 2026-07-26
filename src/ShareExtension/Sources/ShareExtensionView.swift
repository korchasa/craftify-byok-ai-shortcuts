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

    private enum ContentPaddingConstants {
        static let doubleBottomPadding: CGFloat = CraftifyButtonConstants.bottomPadding + CraftifyButtonConstants.bottomPadding
        static let bottomExtra: CGFloat = CraftifyButtonConstants.minButtonHeight + doubleBottomPadding
    }

    public init(viewModel: ShareExtensionViewModel) {
        self.viewModel = viewModel
    }

    /// Add a helper property for the main content
    private var mainContentVStack: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.clear)
                .frame(height: ShareExtensionViewConstants.contentTopSpacing)

            if viewModel.displayResult != nil {
                Text(displayOperationTitle())
                    .font(.craftifyTitle)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, ShareExtensionViewConstants.topPadding)

                Rectangle()
                    .fill(Color.clear)
                    .frame(height: ShareExtensionViewConstants.verticalSpacing)

                DisplayResultView(
                    text: viewModel.displayResult ?? ""
                )
            } else {
                // До выбора операции шапку занимает сам текст: пользователь должен
                // видеть, над чем работает, а не название приложения
                inputPreview
                    .padding(.top, ShareExtensionViewConstants.topPadding)
                    .padding(.bottom, ShareExtensionViewConstants.inputPreviewBottomSpacing)

                operationsGrid
            }
        }
        .padding(.horizontal, CraftifyButtonConstants.horizontalPadding)
        .padding(.bottom, ContentPaddingConstants.bottomExtra)
    }

    // [REF:fr:ux.share-input-preview]
    /// Шапка экрана выбора: над чем работаем. Длинный текст обрезается —
    /// шторка должна оставаться компактной, а сетка операций — видимой
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
                    .lineLimit(ShareExtensionViewConstants.inputPreviewLineLimit)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, CraftifyButtonConstants.horizontalPadding)
        }
    }

    public var body: some View {
        ZStack {
            // Scrollable header + content
            ScrollView {
                mainContentVStack
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(key: ContentHeightKey.self, value: proxy.size.height)
                        }
                    )
            }
            .onPreferenceChange(ContentHeightKey.self) { viewModel.contentHeight = $0 }
            // Processing overlay
            if isProcessing {
                progressOverlay
            }
        }
        // Pin action buttons above the bottom safe area using common button bar
        .safeAreaInset(edge: .bottom) {
            CraftifyButtonBar(backgroundColor: palette.background()) {
                if viewModel.displayResult != nil {
                    closeButton
                    copyAndCloseButton
                } else {
                    closeButton
                }
            }
            // Bottom padding handled by CraftifyButtonBar + safe area; no extra
        }
        .background(palette.background())
        // Keep safe area so bottom inset matches Main screen
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
    /// расставил плитки в приложении, чтобы узнавать их здесь по месту
    private var operationsGrid: some View {
        let cells = OperationGrid.cells(for: viewModel.operations, minimumCells: 0)
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
        .padding(.horizontal, CraftifyButtonConstants.horizontalPadding)
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

    private var closeButton: some View {
        Button(action: { viewModel.shouldCloseExtension = true }) {
            Label(L10n.shareCancel, systemImage: "xmark")
                .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                .foregroundColor(palette.primaryButtonText())
        }
        .buttonStyle(CraftifySecondaryButtonStyle())
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
