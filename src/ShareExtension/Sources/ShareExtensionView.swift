import CraftifyShared
import SwiftUI

// swiftlint:disable:next file_name one_declaration_per_file file_types_order no_grouping_extension convenience_type prefer_self_in_static_references
// Этот файл сгенерирован SwiftGen. Не редактируйте вручную.

public struct ShareExtensionView: View {
    @ObservedObject public var viewModel: ShareExtensionViewModel
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isProcessing = false
    @State private var progress: Double = 0.0

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
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Ошибка"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .padding()
        .background(Color(.systemBackground))
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
                .disabled(isProcessing)
            }
        }
        .padding(.horizontal)
    }

    private func displayName(for type: OperationType) -> String {
        switch type {
        case .translate: return Strings.operationLabelTranslate
        case .simplify: return Strings.operationLabelSimplify
        case .correct: return Strings.operationLabelCorrect
        case .explain: return Strings.operationLabelExplain
        }
    }

    private var progressOverlay: some View {
        VStack(spacing: ShareExtensionViewConstants.verticalSpacing) {
            Text("Обработка...")
                .font(.headline)
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: ShareExtensionViewConstants.progressWidth)
            Text("\(Int(progress * 100))%")
                .font(.subheadline)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: ShareExtensionViewConstants.overlayCornerRadius).fill(Color(.systemBackground).opacity(ShareExtensionViewConstants.overlayOpacity)))
        .shadow(radius: ShareExtensionViewConstants.overlayShadow)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Обработка, прогресс \(Int(progress * 100))%")
    }
}
