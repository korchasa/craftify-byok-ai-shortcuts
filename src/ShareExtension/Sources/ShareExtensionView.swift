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

    private enum ProgressConstants {
        static let percentMax: Double = 100
    }

    private enum ZIndexConstants {
        static let copiedToast: Double = 2
    }

    private let supportedLanguages: [(name: String, code: String)] = [
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

    public init(viewModel: ShareExtensionViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            VStack(spacing: ShareExtensionViewConstants.verticalSpacing) {
                Text("Craftify — Обработка текста")
                    .font(.title2)
                    .bold()
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, ShareExtensionViewConstants.topPadding)
                operationsGrid
                Spacer()
                Button(action: { viewModel.cancel() }) {
                    Text("Отмена")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityLabel("Отмена")
                .buttonStyle(.bordered)
                .padding(.horizontal)
                .padding(.bottom, ShareExtensionViewConstants.bottomPadding)
            }
            .blur(radius: isProcessing ? ShareExtensionViewConstants.blurRadius : 0)
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
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .padding()
        .background(Color(.systemBackground))
        .zIndex(ZIndexConstants.copiedToast)
    }

    private var operationsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ShareExtensionViewConstants.gridSpacing) {
            ForEach(viewModel.operations, id: \ .id) { op in
                Button(action: { viewModel.process(operation: op) }) {
                    Text(operationDisplayName(for: op))
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .accessibilityLabel(operationDisplayName(for: op))
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing || viewModel.isInputTextTooLong)
            }
        }
        .padding(.horizontal)
    }

    private func operationDisplayName(for op: InventoryOperation) -> String {
        switch op.operation {
        case .translate:
            if let params = try? JSONDecoder().decode(TranslateParams.self, from: op.params) {
                let langName = supportedLanguages.first(where: { $0.code == params.targetLanguage })?.name ?? params.targetLanguage
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
            if let params = try? JSONDecoder().decode(CorrectParams.self, from: op.params) {
                return "\(L10n.operationLabelCorrect) \(L10n.operationParamStylePreservation): \(params.stylePreservationLevel)/3"
            }
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
            Text("Обработка...")
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
        .accessibilityLabel("Обработка, прогресс \(Int(progress * ProgressConstants.percentMax))%")
    }

    private var copiedToast: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("Скопировано в буфер")
                    .font(ShareExtensionViewConstants.copiedToastFont)
                    .padding(.vertical, ShareExtensionViewConstants.copiedToastVerticalSpacing)
                    .padding(.horizontal, ShareExtensionViewConstants.copiedToastHorizontalSpacing)
                    .background(
                        RoundedRectangle(cornerRadius: ShareExtensionViewConstants.copiedToastCornerRadius)
                            .fill(Color(.systemGray6).opacity(ShareExtensionViewConstants.copiedToastBackgroundOpacity))
                    )
                    .shadow(radius: ShareExtensionViewConstants.copiedToastShadowRadius)
                Spacer()
            }
            Spacer().frame(height: ShareExtensionViewConstants.copiedToastBottomSpacing)
        }
        .transition(.opacity)
        .zIndex(ZIndexConstants.copiedToast)
    }
}

// swiftlint:disable explicit_acl
extension Notification.Name {
    /// Уведомление для закрытия Share Extension после копирования результата
    static let closeShareExtension = Notification.Name("closeShareExtension")
}

// swiftlint:enable explicit_acl
