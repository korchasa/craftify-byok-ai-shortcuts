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
                    SettingsProviderSection(viewModel: viewModel)

                    SettingsModelSection(viewModel: viewModel)

                    Text(L10n.settingsLlmApiKey)
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
                .accessibilityIdentifier("settings_save_button")
            }
        }
    }

    private struct SettingsApiKeySection: View {
        @ObservedObject var viewModel: SettingsViewModel
        @FocusState var isTextFieldFocused: Bool
        @State private var showDeleteConfirmation = false
        @Environment(\.colorPalette) private var palette
        var body: some View {
            if viewModel.isKeyPresent, !viewModel.isEditingKey {
                maskedKeyRow
            } else {
                editingRow
            }
        }

        /// Сохранённый ключ показывается только короткой маской с действиями «Изменить»/«Удалить»
        private var maskedKeyRow: some View {
            HStack {
                Text(viewModel.maskedApiKey)
                    .font(.craftifyBody)
                    .fontWeight(.regular)
                    .foregroundColor(palette.secondaryText())
                    .accessibilityLabel(L10n.settingsLlmApiKey)
                Spacer()
                Button(L10n.settingsChangeKey) { viewModel.beginEditing() }
                    .font(.craftifyBody)
                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    Text(L10n.settingsDeleteKey)
                        .font(.craftifyBody)
                        .foregroundColor(palette.destructive())
                }
            }
            .confirmationDialog(
                L10n.settingsDeleteKeyConfirm,
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(L10n.settingsDeleteKey, role: .destructive) {
                    Task { await viewModel.deleteKey() }
                }
            }
        }

        /// Ввод нового ключа всегда начинается с пустого поля
        private var editingRow: some View {
            HStack {
                SecureField(L10n.settingsLlmApiKey, text: $viewModel.apiKey)
                    .focused($isTextFieldFocused)
                    .accessibilityLabel(L10n.settingsLlmApiKey)
                if viewModel.isEditingKey {
                    Button(L10n.settingsCancelEditing) { viewModel.cancelEditing() }
                        .font(.craftifyBody)
                }
            }
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

    private struct SettingsModelSection: View {
        @ObservedObject var viewModel: SettingsViewModel
        @State private var showModelPicker = false
        @Environment(\.colorPalette) private var palette
        var body: some View {
            HStack {
                Text(L10n.settingsModel)
                    .font(.craftifyBody)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { showModelPicker = true }) {
                    HStack {
                        Text(viewModel.selectedModel)
                            .font(.craftifyBody)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.craftifyFootnote)
                            .foregroundColor(palette.secondaryText())
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityLabel(L10n.settingsModel)
            }
            .sheet(isPresented: $showModelPicker) {
                ModelPickerSheet(viewModel: viewModel)
            }
        }
    }

    /// Экран выбора модели настроек — обёртка над общим ModelPickerView
    private struct ModelPickerSheet: View {
        @ObservedObject var viewModel: SettingsViewModel
        @Environment(\.dismiss) private var dismiss
        var body: some View {
            ModelPickerView(
                selectedModel: viewModel.selectedModel,
                availableModels: viewModel.availableModels,
                isLoading: viewModel.isLoadingModels,
                loadFailed: viewModel.modelsLoadFailed,
                onSelect: { model in
                    viewModel.selectedModel = model
                    dismiss()
                },
                onRetry: {
                    Task { await viewModel.loadModels() }
                }
            )
            .task {
                if viewModel.availableModels.isEmpty {
                    await viewModel.loadModels()
                }
            }
        }
    }

    private struct SettingsProviderSection: View {
        @ObservedObject var viewModel: SettingsViewModel
        var body: some View {
            HStack {
                Text(LocalizedStringKey(L10n.settingsLlmProvider))
                    .font(.craftifyBody)
                    .fontWeight(.bold)
                Spacer()
                Picker(L10n.settingsLlmProvider, selection: $viewModel.selectedProvider) {
                    ForEach(LLMProvider.allCases, id: \.rawValue) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}
