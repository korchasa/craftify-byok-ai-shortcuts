import Foundation
import SwiftUI

// swiftlint:disable:next file_name one_declaration_per_file file_types_order no_grouping_extension convenience_type prefer_self_in_static_references
// Этот файл сгенерирован SwiftGen. Не редактируйте вручную.

public struct ShareExtensionView: View {
    @ObservedObject public var viewModel: ShareExtensionViewModel
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isProcessing = false
    @State private var progress: Double = 0.0
    @State private var contentHeight: CGFloat = 0
    public var onContentHeightChange: ((CGFloat) -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme
    private var palette: ShareExtensionColorPaletteProviding {
        ShareExtensionColorPaletteFactory.palette(for: colorScheme)
    }

    private enum ProgressConstants {
        static let percentMax: Double = 100
    }

    private enum ZIndexConstants {
        static let copiedToast: Double = 2
    }

    private static let supportedLanguages: [(name: String, code: String)] = [
        ("български", "bg"),
        ("deutsch", "de"),
        ("english", "en"),
        ("español", "es"),
        ("français", "fr"),
        ("日本語", "ja"),
        ("русский", "ru"),
        ("українська", "uk"),
        ("中文", "zh")
    ]

    private enum ShareExtensionViewLocalConstants {
        static let operationHeightMultiplier: CGFloat = 1.5
        static let operationMinHeight: CGFloat = ColorPaletteConstants.circleSize * operationHeightMultiplier
        static let gridColumns: [GridItem] = [GridItem(.flexible()), GridItem(.flexible())]
        static let toastPadding: CGFloat = 8
        static let mainContentTopSpacer: CGFloat = 12
        static let cardCornerRadius: CGFloat = 12
        static let closeButtonTopPadding: CGFloat = 12
        static let closeButtonBottomPadding: CGFloat = 24
        static let vStackSpacing: CGFloat = 0
        static let closeButtonBackgroundOpacity: CGFloat = 0.15
    }

    public init(viewModel: ShareExtensionViewModel) {
        self.viewModel = viewModel
    }

    // Add a helper property for the main content
    private var mainContentVStack: some View {
        VStack(spacing: ShareExtensionViewLocalConstants.vStackSpacing) {
            Rectangle()
                .fill(Color.clear)
                .frame(height: ShareExtensionViewLocalConstants.mainContentTopSpacer)

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
                    text: viewModel.displayResult ?? "",
                    onClose: { viewModel.shouldCloseExtension = true }
                )
            } else {
                operationsGrid
            }
        }
        .padding(.horizontal, ShareExtensionButtonConstants.horizontalPadding)
    }

    public var body: some View {
        ZStack {
            // Scrollable header + content
            ScrollView {
                mainContentVStack
            }
            // Processing overlay
            if isProcessing {
                progressOverlay
            }
            // Copied toast overlay
            if viewModel.showCopiedToast {
                copiedToast
            }
        }
        // Pin the close button above the bottom safe area with fixed padding
        .safeAreaInset(edge: .bottom) {
            closeButton
                .padding(.horizontal, ShareExtensionButtonConstants.horizontalPadding)
                .padding(.bottom, ShareExtensionButtonConstants.bottomPadding)
                .background(palette.background())
        }
        .background(palette.background())
        .ignoresSafeArea(edges: .bottom)
        .zIndex(ZIndexConstants.copiedToast)
        .environment(\.shareExtensionColorPalette, palette)
        // ViewModel subscriptions & alerts
        .onReceive(viewModel.$errorMessage) { msg in
            if let msg {
                alertMessage = msg
                showAlert = true
            }
        }
        .onReceive(viewModel.$isProcessing) { isProcessing = $0 }
        .onReceive(viewModel.$progress) { progress = $0 }
        .onReceive(viewModel.$showCopiedToast) { show in
            if show {
                DispatchQueue.main.asyncAfter(deadline: .now() + ShareExtensionViewConstants.copiedToastHideDelay) {
                    viewModel.hideCopiedToast()
                }
            }
        }
        .onReceive(viewModel.$shouldCloseExtension) { shouldClose in
            if shouldClose {
                NotificationCenter.default.post(name: .closeShareExtension, object: nil)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(L10n.error), message: Text(alertMessage), dismissButton: .default(Text(LocalizedStringKey("OK"))))
        }
    }

    private var operationsGrid: some View {
        let cardCornerRadius: CGFloat = ShareExtensionViewLocalConstants.cardCornerRadius
        let symbolScale: CGFloat = 0.5
        let vStackSpacing: CGFloat = 4
        let hStackSpacing: CGFloat = 6
        return LazyVGrid(columns: ShareExtensionViewLocalConstants.gridColumns, spacing: ShareExtensionViewConstants.gridSpacing) {
            ForEach(viewModel.operations, id: \ .id) { op in
                operationButton(for: op, cardCornerRadius: cardCornerRadius, symbolScale: symbolScale, vStackSpacing: vStackSpacing, hStackSpacing: hStackSpacing)
            }
        }
        .padding(.horizontal, ShareExtensionButtonConstants.horizontalPadding)
    }

    private func operationButton(for op: InventoryOperation, cardCornerRadius: CGFloat, symbolScale: CGFloat, vStackSpacing: CGFloat, hStackSpacing: CGFloat) -> some View {
        let color = Color(hex: op.colorHex)
        return Button(action: { viewModel.process(operation: op) }) {
            VStack(spacing: vStackSpacing) {
                HStack(spacing: hStackSpacing) {
                    ZStack {
                        Image(systemName: op.operation.sfSymbol)
                            .foregroundColor(palette.primaryButtonText())
                            .font(.system(size: ColorPaletteConstants.circleSize * symbolScale))
                            .fontWeight(.semibold)
                            .accessibilityLabel("SF Symbol for operation: \(op.operation.rawValue)")
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
            .frame(maxWidth: .infinity, minHeight: ShareExtensionViewLocalConstants.operationMinHeight)
            .padding()
            .background(color)
            .foregroundColor(palette.primaryButtonText())
            .cornerRadius(cardCornerRadius)
        }
        .accessibilityLabel(operationCategory(for: op))
        .disabled(viewModel.isProcessing || viewModel.isInputTextTooLong)
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
                let langName = ShareExtensionView.supportedLanguages.first(where: { $0.code == params.targetLanguage })?.name ?? params.targetLanguage
                return "\u{2192} " + langName
            }
            return ""
        case .simplify:
            if let params = try? JSONDecoder().decode(SimplifyParams.self, from: op.params) {
                switch params.complexityLevel {
                case .schoolchild: return L10n.operationValueSchoolchild
                case .teenager: return L10n.operationValueTeenager
                case .student: return L10n.operationValueStudent
                case .adult: return L10n.operationValueAdult
                }
            }
            return ""
        case .correct:
            return ""
        case .explain:
            if let params = try? JSONDecoder().decode(ExplainParams.self, from: op.params) {
                switch params.detailLevel {
                case .schoolchild: return L10n.operationValueSchoolchild
                case .teenager: return L10n.operationValueTeenager
                case .student: return L10n.operationValueStudent
                case .adult: return L10n.operationValueAdult
                }
            }
            return ""
        case .summarize:
            if let params = try? JSONDecoder().decode(SummarizeParams.self, from: op.params) {
                return sentenceCountRangeLabel(params.sentenceCountRange)
            }
            return ""
        }
    }

    private func sentenceCountRangeLabel(_ range: SentenceCountRange) -> String {
        switch range {
        case .twoToThree: L10n.sentenceCount23
        case .fiveToSix: L10n.sentenceCount56
        case .nineToTen: L10n.sentenceCount910
        }
    }

    private var progressOverlay: some View {
        VStack(spacing: ShareExtensionViewConstants.verticalSpacing) {
            Text(L10n.processing)
                .font(.craftifyBody)
                .fontWeight(.semibold)
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: ShareExtensionViewConstants.progressWidth)
            Text(String.localizedStringWithFormat(NSLocalizedString("percent_format", bundle: Bundle(for: ShareExtensionViewModel.self), comment: ""), Int(progress * ProgressConstants.percentMax)))
                .font(.craftifyFootnote)
                .fontWeight(.semibold)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: ShareExtensionViewConstants.overlayCornerRadius).fill(Color(.systemBackground).opacity(ShareExtensionViewConstants.overlayOpacity)))
        .shadow(radius: ShareExtensionViewConstants.overlayShadow)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(L10n.processing), progress \(Int(progress * ProgressConstants.percentMax))%")
    }

    private var copiedToast: some View {
        VStack {
            Rectangle()
                .fill(Color.clear)
                .frame(height: ShareExtensionViewLocalConstants.toastPadding)
            HStack {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: ShareExtensionViewLocalConstants.toastPadding)
                Text(L10n.copiedToClipboard)
                    .font(.craftifyBody)
                    .fontWeight(.bold)
                    .padding(.vertical, ShareExtensionViewConstants.copiedToastVerticalSpacing)
                    .padding(.horizontal, ShareExtensionViewConstants.copiedToastHorizontalSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: ShareExtensionViewConstants.copiedToastCornerRadius)
                            .fill(Color(.systemGray6).opacity(ShareExtensionViewConstants.copiedToastBackgroundOpacity))
                    )
                    .shadow(radius: ShareExtensionViewConstants.copiedToastShadowRadius)
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: ShareExtensionViewLocalConstants.toastPadding)
            }
            Rectangle()
                .fill(Color.clear)
                .frame(height: ShareExtensionViewConstants.copiedToastBottomSpacing)
        }
        .transition(.opacity)
        .zIndex(ZIndexConstants.copiedToast)
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
        let onClose: () -> Void
        var body: some View {
            Text(text)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding()
        }
    }

    private var closeButton: some View {
        Button(action: { viewModel.shouldCloseExtension = true }) {
            Label(L10n.shareClose, systemImage: "xmark")
                .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                .foregroundColor(palette.primaryButtonText())
        }
        .buttonStyle(CraftifySecondaryButtonStyle())
        .padding(.horizontal, CraftifyButtonConstants.horizontalPadding)
        .padding(.bottom, CraftifyButtonConstants.bottomPadding)
    }
}
