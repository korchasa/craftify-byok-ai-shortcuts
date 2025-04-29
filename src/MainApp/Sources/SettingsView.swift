import Common
import SwiftUI
import UniformTypeIdentifiers

/// Экран настроек Craftify: управление API-ключом и согласием пользователя
public struct SettingsView: View {
    /// ViewModel для управления состоянием экрана
    @ObservedObject public var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool

    /// Инициализация с ViewModel
    /// - Parameter viewModel: ViewModel настроек
    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: SettingsViewConstants.verticalSpacing) {
            titleSection
            apiKeySection
            errorSection
            Spacer()
            buttonsSection
        }
        .onAppear { isTextFieldFocused = true }
        .disabled(viewModel.isLoading)
        .overlay(loadingOverlay)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var titleSection: some View {
        Text(L10n.settingsTitle)
            .font(.title2)
            .bold()
            .accessibilityAddTraits(.isHeader)
            .padding(.top, SettingsViewConstants.topPadding)
    }

    @ViewBuilder
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: SettingsViewConstants.fieldSpacing) {
            Text(L10n.settingsApiKey)
                .font(.headline)
            SecureField(L10n.settingsApiKey, text: $viewModel.apiKey)
                .focused($isTextFieldFocused)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(L10n.settingsApiKey)
            if viewModel.isKeyPresent {
                HStack {
                    Text(viewModel.maskedApiKey)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(role: .destructive, action: { Task { await viewModel.deleteKey() } }) {
                        Text(L10n.homeDelete)
                    }
                    .accessibilityLabel(L10n.homeDelete + " ключ")
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var errorSection: some View {
        if let error = viewModel.errorMessage {
            Text(error)
                .foregroundColor(.red)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
                .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private var buttonsSection: some View {
        HStack(spacing: SettingsViewConstants.buttonSpacing) {
            Button(action: { dismiss() }) {
                Text(L10n.settingsDone)
                    .frame(maxWidth: .infinity)
            }
            .accessibilityLabel(L10n.settingsDone)
            .buttonStyle(.bordered)

            Button(action: { Task { await viewModel.saveKey() } }) {
                Text(L10n.addOperationSave)
                    .frame(maxWidth: .infinity)
            }
            .accessibilityLabel(L10n.addOperationSave + " ключ")
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal)
        .padding(.bottom, SettingsViewConstants.bottomPadding)
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(SettingsViewConstants.loadingScale)
        }
    }
}
