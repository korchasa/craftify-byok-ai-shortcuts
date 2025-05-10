import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Экран настроек Craftify: управление API-ключом и согласием пользователя
public struct SettingsView: View {
    /// ViewModel для управления состоянием экрана
    @ObservedObject public var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    @State private var shouldDismiss = false
    @Environment(\.colorPalette) private var palette

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
                    Text(L10n.settingsApiKey)
                        .font(.craftifyBody)
                        .fontWeight(.bold)
                    SettingsApiKeySection(viewModel: viewModel, isTextFieldFocused: _isTextFieldFocused)

                    HStack {
                        Text(L10n.settingsNativeLanguage)
                            .font(.craftifyBody)
                            .fontWeight(.bold)
                        Spacer()
                        Picker(L10n.settingsNativeLanguage, selection: $viewModel.selectedNativeLanguage) {
                            ForEach(viewModel.supportedLanguages, id: \.code) { lang in
                                Text(lang.name).tag(lang.code)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    Text(L10n.settingsNativeLanguageSection)
                        .font(.craftifyFootnote)
                        .fontWeight(.regular)
                        .foregroundColor(palette.secondaryText())
                        .padding(.top, FormStyleConstants.nativeLanguageSectionTopPadding)

                    SettingsErrorSection(errorMessage: viewModel.errorMessage)
                }
                .padding(.leading, FormStyleConstants.formLeadingPadding)
                .padding(.trailing, FormStyleConstants.formTrailingPadding)
            },
            buttons: {
                SettingsFormButtons(viewModel: viewModel, dismiss: dismiss, shouldDismiss: $shouldDismiss)
            }
        )
        .onChange(of: shouldDismiss) { newValue in
            if newValue {
                dismiss()
            }
        }
        .background(palette.background())
    }

    private struct SettingsFormButtons: View {
        @ObservedObject var viewModel: SettingsViewModel
        var dismiss: DismissAction
        @Binding var shouldDismiss: Bool
        @Environment(\.colorPalette) private var palette
        var body: some View {
            CraftifyButtonBar(backgroundColor: palette.background()) {
                Button(action: { dismiss() }) {
                    Label(L10n.settingsDone, systemImage: "xmark")
                        .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                        .foregroundColor(palette.secondaryButtonText())
                }
                .buttonStyle(CraftifySecondaryButtonStyle())
                Button(action: {
                    Task {
                        viewModel.saveNativeLanguage()
                        await viewModel.saveKey()
                        if viewModel.errorMessage == nil {
                            shouldDismiss = true
                        }
                    }
                }) {
                    Label(L10n.addOperationSave, systemImage: "checkmark")
                        .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                        .foregroundColor(palette.primaryButtonText())
                }
                .buttonStyle(CraftifyPrimaryButtonStyle())
                .disabled(viewModel.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
        }
    }

    private struct SettingsApiKeySection: View {
        @ObservedObject var viewModel: SettingsViewModel
        @FocusState var isTextFieldFocused: Bool
        @Environment(\.colorPalette) private var palette
        var body: some View {
            SecureField(L10n.settingsApiKey, text: $viewModel.apiKey)
                .focused($isTextFieldFocused)
                .accessibilityLabel(L10n.settingsApiKey)
        }
    }

    private struct SettingsErrorSection: View {
        var errorMessage: String?
        @Environment(\.colorPalette) private var palette
        var body: some View {
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(palette.destructive())
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
