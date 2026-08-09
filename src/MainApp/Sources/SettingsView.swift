import Foundation
import os
import SwiftUI
import UniformTypeIdentifiers

/// Экран настроек Craftify: управление API-ключом и согласием пользователя
public struct SettingsView: View {
    /// ViewModel для управления состоянием экрана
    @ObservedObject public var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.colorPalette) private var palette
    /// Диагностика полевого iPad-бага: шит настроек закрывался при тапе по строке модели
    fileprivate static let uiLog = OSLog(subsystem: "Internal", category: "SettingsUI")

    /// Инициализация с ViewModel
    /// - Parameter viewModel: ViewModel настроек
    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        CommonFormContainer(
            title: LocalizedStringKey(L10n.settingsTitle),
            content: { _ in
                VStack(alignment: .leading, spacing: FormStyleConstants.sectionSpacing) {
                    SettingsProviderSection(viewModel: viewModel)

                    SettingsModelSection(viewModel: viewModel)

                    Text(L10n.settingsLlmApiKey)
                        .font(.craftifyBody)
                        .fontWeight(.bold)
                    SettingsApiKeySection(viewModel: viewModel, isTextFieldFocused: _isTextFieldFocused)
                    // Сообщение стоит вплотную к ключу: почти все ошибки здесь
                    // про него, а внизу формы оно оказывалось через две строки
                    // от поля и не связывалось с ним
                    SettingsErrorSection(errorMessage: viewModel.errorMessage)

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
                }
                .padding(.leading, FormStyleConstants.formLeadingPadding)
                .padding(.trailing, FormStyleConstants.formTrailingPadding)
            },
            buttons: {
                SettingsFormButtons(dismiss: dismiss)
            }
        )
        .onAppear {
            os_log("%{public}@", log: SettingsView.uiLog, type: .info, "settings appeared")
        }
        .onDisappear {
            os_log("%{public}@", log: SettingsView.uiLog, type: .info, "settings disappeared")
        }
        .background(palette.background())
    }

    /// Внизу экрана только выход. Общей кнопки сохранения здесь нет: провайдер,
    /// модель и родной язык применяются сразу при выборе, а ключ сохраняется
    /// своей кнопкой рядом с полем ввода. Прежняя кнопка «Сохранить» выглядела
    /// так, будто относится ко всей форме, и оставалась серой после смены языка.
    ///
    /// Кнопка нарочно второстепенная, со стрелкой вниз: она ничего не сохраняет
    /// и ничего не отменяет, а только закрывает лист. Основной зелёный стиль с
    /// галочкой обещал бы действие, которого здесь нет
    private struct SettingsFormButtons: View {
        var dismiss: DismissAction
        @Environment(\.colorPalette) private var palette
        var body: some View {
            CraftifyButtonBar(backgroundColor: palette.background()) {
                Button(action: { dismiss() }) {
                    Label(L10n.settingsDone, systemImage: "chevron.down")
                        .frame(maxWidth: .infinity, minHeight: CraftifyButtonConstants.minButtonHeight)
                        .foregroundColor(.primary)
                }
                .buttonStyle(CraftifySecondaryButtonStyle())
                .accessibilityIdentifier("settings_done_button")
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
                    .accessibilityIdentifier("settings_change_key_button")
                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    Text(L10n.settingsDeleteKey)
                        .font(.craftifyBody)
                        .foregroundColor(palette.destructive())
                }
            }
            // Предупреждение, а не confirmationDialog: тот выходил выноской и
            // прятал кнопку отмены, так что уйти из необратимого действия можно
            // было только тапом мимо. Alert всегда рисует обе кнопки
            .alert(L10n.settingsDeleteKeyConfirm, isPresented: $showDeleteConfirmation) {
                Button(L10n.settingsDeleteKey, role: .destructive) {
                    Task { await viewModel.deleteKey() }
                }
                Button(L10n.settingsCancelEditing, role: .cancel) {}
            }
        }

        /// Ввод нового ключа всегда начинается с пустого поля. Сохранение живёт
        /// здесь же: ключ — единственная настройка, которую нельзя применить
        /// сразу, потому что он проверяется запросом к провайдеру
        private var editingRow: some View {
            HStack {
                SecureField(L10n.settingsLlmApiKeyPlaceholder, text: $viewModel.apiKey)
                    .focused($isTextFieldFocused)
                    .accessibilityLabel(L10n.settingsLlmApiKey)
                Button(L10n.addOperationSave) {
                    Task { await viewModel.saveKey() }
                }
                .font(.craftifyBody)
                .disabled(viewModel.apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
                .accessibilityIdentifier("settings_save_button")
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
                Button(action: {
                    os_log("%{public}@", log: SettingsView.uiLog, type: .info, "model row tapped")
                    showModelPicker = true
                }) {
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
                .accessibilityIdentifier("settings_model_button")
            }
            // Пуш внутри NavigationStack настроек, а не вложенная презентация
            // (sheet/popover): на iPad активация поиска во вложенной презентации
            // системно сбрасывала и пикер, и шит настроек — несохранённый ключ терялся
            .navigationDestination(isPresented: $showModelPicker) {
                ModelPickerSheet(viewModel: viewModel)
            }
            .onChange(of: showModelPicker) { newValue in
                os_log("%{public}@", log: SettingsView.uiLog, type: .info, "model picker presented: \(newValue)")
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
                .accessibilityIdentifier("settings_provider_picker")
            }
        }
    }
}
