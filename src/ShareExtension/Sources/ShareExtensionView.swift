import CraftifyShared
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
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .padding()
        .background(Color(.systemBackground))
        .zIndex(ZIndexConstants.copiedToast)
    }

    private var operationsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: ShareExtensionViewConstants.gridSpacing) {
            ForEach(viewModel.operations, id: \.id) { op in
                Button(action: { viewModel.process(operation: op) }) {
                    Text(displayName(for: op.operation))
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .accessibilityLabel(displayName(for: op.operation))
                .buttonStyle(.borderedProminent)
                .disabled(isProcessing || viewModel.isInputTextTooLong)
            }
        }
        .padding(.horizontal)
    }

    private func displayName(for type: OperationType) -> String {
        switch type {
        case .translate: L10n.operationLabelTranslate
        case .simplify: L10n.operationLabelSimplify
        case .correct: L10n.operationLabelCorrect
        case .explain: L10n.operationLabelExplain
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
