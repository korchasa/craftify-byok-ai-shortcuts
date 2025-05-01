import Common
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
    }

    public init(viewModel: ShareExtensionViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            mainContent
            Button(action: { viewModel.shouldCloseExtension = true }) {
                Image(systemName: "xmark")
                    .imageScale(.large)
                    .accessibilityLabel("Закрыть")
            }
            .accessibilityIdentifier("closeButton")
            .buttonStyle(.plain)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .allowsHitTesting(!isProcessing)
            if isProcessing {
                progressOverlay
            }
            if viewModel.showCopiedToast {
                copiedToast
            }
        }
        .onReceive(viewModel.$errorMessage) { msg in
            if let msg {
                alertMessage = msg
                showAlert = true
            }
        }
        .onReceive(viewModel.$isProcessing) { val in
            isProcessing = val
        }
        .onReceive(viewModel.$progress) { val in
            progress = val
        }
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
            Alert(title: Text(L10n.error), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .padding()
        .background(Color(.systemBackground))
        .zIndex(ZIndexConstants.copiedToast)
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.clear)
                .frame(height: ShareExtensionViewLocalConstants.mainContentTopSpacer)
            Text(L10n.shareTitle)
                .font(.title2)
                .bold()
                .accessibilityAddTraits(.isHeader)
                .padding(.top, ShareExtensionViewConstants.topPadding)
            Rectangle()
                .fill(Color.clear)
                .frame(height: ShareExtensionViewConstants.verticalSpacing)
            operationsGrid
                .padding(.bottom, ShareExtensionViewConstants.bottomPadding)
        }
    }

    private var operationsGrid: some View {
        let cardCornerRadius: CGFloat = ShareExtensionViewLocalConstants.cardCornerRadius
        return LazyVGrid(columns: ShareExtensionViewLocalConstants.gridColumns, spacing: ShareExtensionViewConstants.gridSpacing) {
            ForEach(viewModel.operations, id: \ .id) { op in
                let color = Color(hex: op.colorHex)
                Button(action: { viewModel.process(operation: op) }) {
                    Text(operationDisplayName(for: op))
                        .frame(maxWidth: .infinity, minHeight: ShareExtensionViewLocalConstants.operationMinHeight)
                        .padding()
                        .background(color)
                        .foregroundColor(color.isDarkColor ? .white : .black)
                        .cornerRadius(cardCornerRadius)
                }
                .accessibilityLabel(operationDisplayName(for: op))
                .buttonStyle(.plain)
                .disabled(viewModel.isProcessing || viewModel.isInputTextTooLong)
            }
        }
        .padding(.horizontal)
    }

    private func operationDisplayName(for op: InventoryOperation) -> String {
        switch op.operation {
        case .translate:
            if let params = try? JSONDecoder().decode(TranslateParams.self, from: op.params) {
                let langName = ShareExtensionView.supportedLanguages.first(where: { $0.code == params.targetLanguage })?.name ?? params.targetLanguage
                return "\(L10n.operationLabelTranslate) → \(langName)"
            }
            return L10n.operationLabelTranslate
        case .simplify:
            if let params = try? JSONDecoder().decode(SimplifyParams.self, from: op.params) {
                let level: String = switch params.complexityLevel {
                case .beginner: L10n.operationValueBeginner
                case .intermediate: L10n.operationValueIntermediate
                case .advanced: L10n.operationValueAdvanced
                }
                return "\(L10n.operationLabelSimplify) \(level)"
            }
            return L10n.operationLabelSimplify
        case .correct:
            return L10n.operationLabelCorrect
        case .explain:
            if let params = try? JSONDecoder().decode(ExplainParams.self, from: op.params) {
                let level: String = switch params.detailLevel {
                case .beginner: L10n.operationValueBeginner
                case .intermediate: L10n.operationValueIntermediate
                case .advanced: L10n.operationValueAdvanced
                }
                return "\(L10n.operationLabelExplain) \(level)"
            }
            return L10n.operationLabelExplain
        }
    }

    private var progressOverlay: some View {
        VStack(spacing: ShareExtensionViewConstants.verticalSpacing) {
            Text(L10n.processing)
                .font(.headline)
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: ShareExtensionViewConstants.progressWidth)
            Text("\(Int(progress * ProgressConstants.percentMax))%")
                .font(.subheadline)
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
                    .font(ShareExtensionViewConstants.copiedToastFont)
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
}
