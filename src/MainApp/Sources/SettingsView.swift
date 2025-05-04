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
        NavigationStack {
            SettingsForm(viewModel: viewModel, dismiss: dismiss, isTextFieldFocused: _isTextFieldFocused)
        }
        .background(Color.white)
    }

    private struct SettingsForm: View {
        @ObservedObject var viewModel: SettingsViewModel
        var dismiss: DismissAction
        @FocusState var isTextFieldFocused: Bool
        var body: some View {
            VStack(spacing: 0) {
                SettingsFormContent(viewModel: viewModel, isTextFieldFocused: _isTextFieldFocused, dismiss: dismiss)
            }
        }
    }

    private struct SettingsFormContent: View {
        @ObservedObject var viewModel: SettingsViewModel
        @FocusState var isTextFieldFocused: Bool
        var dismiss: DismissAction
        var body: some View {
            Form {
                SettingsApiKeySection(viewModel: viewModel, isTextFieldFocused: _isTextFieldFocused)
                SettingsErrorSection(errorMessage: viewModel.errorMessage)
            }
            .padding(.leading, FormStyleConstants.formLeadingPadding)
            .navigationTitle(L10n.settingsTitle)
            .font(.craftifyTitle)
            .fontWeight(.bold)
            .scrollContentBackground(.hidden)
            .background(Color.white)
            Spacer(minLength: MainAppButtonConstants.spacerMinLength)
            SettingsFormButtons(viewModel: viewModel, dismiss: dismiss)
        }
    }

    private struct SettingsFormButtons: View {
        @ObservedObject var viewModel: SettingsViewModel
        var dismiss: DismissAction
        var body: some View {
            HStack(spacing: MainAppButtonConstants.horizontalPadding) {
                Button(action: { dismiss() }) {
                    Label(L10n.settingsDone, systemImage: "xmark")
                        .font(.craftifyBody)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .buttonStyle(CraftifySecondaryButtonStyle())
                .accessibilityLabel(L10n.settingsDone)
                Button(action: {
                    Task {
                        await viewModel.saveKey()
                    }
                }) {
                    Label(L10n.addOperationSave, systemImage: "checkmark")
                        .font(.craftifyBody)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .buttonStyle(CraftifyPrimaryButtonStyle())
                .accessibilityLabel(L10n.addOperationSave + " ключ")
                .disabled(viewModel.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal, MainAppButtonConstants.horizontalPadding)
            .padding(.bottom, MainAppButtonConstants.bottomPadding)
            .background(Color.white.ignoresSafeArea())
        }
    }

    private struct SettingsApiKeySection: View {
        @ObservedObject var viewModel: SettingsViewModel
        @FocusState var isTextFieldFocused: Bool
        var body: some View {
            Section(header: Text(L10n.settingsApiKey).craftifySectionHeader()) {
                SecureField(L10n.settingsApiKey, text: $viewModel.apiKey)
                    .focused($isTextFieldFocused)
                    .accessibilityLabel(L10n.settingsApiKey)
                if viewModel.isKeyPresent {
                    Text(viewModel.maskedApiKey)
                        .font(.craftifyFootnote)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .lineLimit(Common.unlimitedLineLimit)
                        .fixedSize(horizontal: Common.fixedSizeHorizontal, vertical: Common.fixedSizeVertical)
                }
                if viewModel.isKeyPresent {
                    Button(role: .destructive, action: { Task { await viewModel.deleteKey() } }) {
                        Text(L10n.homeDelete)
                            .font(.craftifyBody)
                            .fontWeight(.bold)
                    }
                    .accessibilityLabel(L10n.homeDelete + " ключ")
                }
            }
        }
    }

    private struct SettingsErrorSection: View {
        var errorMessage: String?
        var body: some View {
            if let error = errorMessage {
                Section(header: Text("").craftifySectionHeader()) {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.craftifyFootnote)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .lineLimit(Common.unlimitedLineLimit)
                        .fixedSize(horizontal: Common.fixedSizeHorizontal, vertical: Common.fixedSizeVertical)
                }
            }
        }
    }

    private struct SettingsLoadingOverlay: View {
        var isLoading: Bool
        var body: some View {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(SettingsViewConstants.loadingScale)
            }
        }
    }
}

private extension View {
    func craftifySectionHeader() -> some View {
        self.font(.system(size: craftifySectionHeaderFontSize, weight: .bold))
            .foregroundColor(.secondary)
            .padding(.leading, FormStyleConstants.titleLeadingPadding)
    }
}
