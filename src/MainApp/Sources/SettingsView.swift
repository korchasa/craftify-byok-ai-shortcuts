import Foundation
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
        CommonFormContainer(
            title: LocalizedStringKey(L10n.settingsTitle),
            content: {
                VStack(alignment: .leading, spacing: FormStyleConstants.sectionSpacing) {
                    Section(header: Text(L10n.settingsApiKey).font(.craftifyTitle).fontWeight(.bold)) {
                        SettingsApiKeySection(viewModel: viewModel, isTextFieldFocused: _isTextFieldFocused)
                    }
                    Section {
                        SettingsErrorSection(errorMessage: viewModel.errorMessage)
                    }
                }
                .padding(.leading, FormStyleConstants.formLeadingPadding)
                .padding(.trailing, FormStyleConstants.formTrailingPadding)
            },
            buttons: {
                SettingsFormButtons(viewModel: viewModel, dismiss: dismiss)
            }
        )
    }

    private struct SettingsFormButtons: View {
        @ObservedObject var viewModel: SettingsViewModel
        var dismiss: DismissAction
        var body: some View {
            CraftifyButtonBar {
                Button(action: { dismiss() }) {
                    Label(L10n.settingsDone, systemImage: "xmark")
                        .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                }
                .buttonStyle(CraftifySecondaryButtonStyle())
                Button(action: {
                    Task {
                        await viewModel.saveKey()
                    }
                }) {
                    Label(L10n.addOperationSave, systemImage: "checkmark")
                        .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                }
                .buttonStyle(CraftifyPrimaryButtonStyle())
                .disabled(viewModel.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
        }
    }

    private struct SettingsApiKeySection: View {
        @ObservedObject var viewModel: SettingsViewModel
        @FocusState var isTextFieldFocused: Bool
        var body: some View {
            SecureField(L10n.settingsApiKey, text: $viewModel.apiKey)
                .focused($isTextFieldFocused)
                .accessibilityLabel(L10n.settingsApiKey)
            if viewModel.isKeyPresent {
                Text(viewModel.maskedApiKey)
                    .font(.craftifyFootnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .lineLimit(ViewConstants.unlimitedLineLimit)
                    .fixedSize(horizontal: ViewConstants.fixedSizeHorizontal, vertical: ViewConstants.fixedSizeVertical)
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

    private struct SettingsErrorSection: View {
        var errorMessage: String?
        var body: some View {
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.craftifyFootnote)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(ViewConstants.unlimitedLineLimit)
                    .fixedSize(horizontal: ViewConstants.fixedSizeHorizontal, vertical: ViewConstants.fixedSizeVertical)
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
