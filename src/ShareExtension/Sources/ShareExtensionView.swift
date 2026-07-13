import Foundation
import SwiftUI

public struct ShareExtensionView: View {
    @ObservedObject public var viewModel: ShareExtensionViewModel
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isProcessing = false
    @Environment(\.colorScheme) private var colorScheme
    /// Символ операции и минимальная высота карточки масштабируются с Dynamic Type
    @ScaledMetric(relativeTo: .body) private var operationSymbolSize: CGFloat =
        ColorPaletteConstants.circleSize * ShareExtensionViewConstants.operationSymbolScale
    @ScaledMetric(relativeTo: .body) private var operationMinHeight: CGFloat =
        ShareExtensionViewConstants.operationMinHeight
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
            } else {
                Text(L10n.shareTitle)
                    .font(.craftifyTitle)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, ShareExtensionViewConstants.topPadding)
            }

            Rectangle()
                .fill(Color.clear)
                .frame(height: ShareExtensionViewConstants.verticalSpacing)

            if viewModel.displayResult != nil {
                DisplayResultView(
                    text: viewModel.displayResult ?? ""
                )
            } else {
                operationsGrid
            }
        }
        .padding(.horizontal, CraftifyButtonConstants.horizontalPadding)
        .padding(.bottom, ContentPaddingConstants.bottomExtra)
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
            Alert(title: Text(L10n.error), message: Text(alertMessage), dismissButton: .default(Text(LocalizedStringKey("OK"))))
        }
        .onChange(of: showAlert) { newValue in
            if !newValue, !alertMessage.isEmpty {
                // alert был закрыт — возвращаемся к сетке операций, чтобы пользователь мог повторить попытку
                viewModel.dismissError()
                alertMessage = ""
            }
        }
    }

    private var operationsGrid: some View {
        let cardCornerRadius: CGFloat = 12
        let vStackSpacing: CGFloat = 4
        let hStackSpacing: CGFloat = 6
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ShareExtensionViewConstants.gridSpacing) {
            ForEach(viewModel.operations, id: \ .id) { op in
                operationButton(for: op, cardCornerRadius: cardCornerRadius, vStackSpacing: vStackSpacing, hStackSpacing: hStackSpacing)
            }
        }
        .padding(.horizontal, CraftifyButtonConstants.horizontalPadding)
    }

    private func operationButton(for op: InventoryOperation, cardCornerRadius: CGFloat, vStackSpacing: CGFloat, hStackSpacing: CGFloat) -> some View {
        let color = Color(hex: op.colorHex)
        return Button(action: { viewModel.process(operation: op) }) {
            VStack(spacing: vStackSpacing) {
                HStack(spacing: hStackSpacing) {
                    ZStack {
                        Image(systemName: op.operation.sfSymbol)
                            .foregroundColor(palette.operationSymbolColor())
                            .font(.system(size: operationSymbolSize))
                            .fontWeight(.semibold)
                            .accessibilityHidden(true)
                    }
                    Text(operationCategory(for: op))
                        .font(.craftifyBody)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(operationProperty(for: op))
                    .font(.craftifyFootnote)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, minHeight: operationMinHeight)
            .padding()
            .background(color)
            .foregroundColor(palette.primaryButtonText())
            .cornerRadius(cardCornerRadius)
        }
        .accessibilityLabel(operationCategory(for: op))
        .disabled(viewModel.isProcessing)
    }

    private func operationCategory(for op: InventoryOperation) -> String {
        switch op.operation {
        case .translate: L10n.operationLabelTranslate
        case .simplify: L10n.operationLabelSimplify
        case .correct: L10n.operationLabelCorrect
        case .explain: L10n.operationLabelExplain
        case .summarize: L10n.operationLabelSummarize
        }
    }

    private func operationProperty(for op: InventoryOperation) -> String {
        switch op.operation {
        case .translate:
            if let params = try? JSONDecoder().decode(TranslateParams.self, from: op.params) {
                let langName = SupportedLanguages.all.first { $0.code == params.targetLanguage }?.name ?? params.targetLanguage
                return "\u{2192} " + langName
            }
            return ""
        case .simplify:
            return ""
        case .correct:
            return ""
        case .explain:
            return ""
        case .summarize:
            if let params = try? JSONDecoder().decode(SummarizeParams.self, from: op.params) {
                return params.length
            }
            return ""
        }
    }

    private var progressOverlay: some View {
        VStack(spacing: ShareExtensionViewConstants.verticalSpacing) {
            ProgressView()
                .progressViewStyle(.circular)
            Text(L10n.processing)
                .font(.craftifyBody)
                .fontWeight(.semibold)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: ShareExtensionViewConstants.overlayCornerRadius).fill(Color(.systemBackground).opacity(ShareExtensionViewConstants.overlayOpacity)))
        .shadow(radius: ShareExtensionViewConstants.overlayShadow)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.processing)
    }

    /// Возвращает локализованное название текущей операции для заголовка окна
    private func displayOperationTitle() -> String {
        guard let op = viewModel.operations.first(where: { viewModel.displayResult != nil && $0.operation == viewModel.manager.lastOperationKind }) else {
            return L10n.shareTitle
        }
        return operationTitle(for: op.operation)
    }

    /// Возвращает только название операции без параметров
    private func operationTitle(for kind: OperationKind) -> String {
        switch kind {
        case .translate: L10n.operationLabelTranslate
        case .simplify: L10n.operationLabelSimplify
        case .correct: L10n.operationLabelCorrect
        case .explain: L10n.operationLabelExplain
        case .summarize: L10n.operationLabelSummarize
        }
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
