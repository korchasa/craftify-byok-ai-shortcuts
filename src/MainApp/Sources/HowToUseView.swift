import SwiftUI

// swiftlint:disable:next explicit_import
public struct HowToUseView: View {
    private static let verticalSpacing: CGFloat = 24
    private static let topPadding: CGFloat = 32
    private static let dividerVerticalPadding: CGFloat = 8
    private static let bottomPadding: CGFloat = 24

    @ObservedObject private var viewModel: HowToUseViewModel
    private var onConsent: (() -> Void)?
    @Environment(\.colorPalette) private var palette

    public var body: some View {
        ZStack {
            // Background covers full screen but keeps content in safe area
            palette.background()
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Self.verticalSpacing) {
                    HowToUseTitle(topPadding: Self.topPadding)
                    HowToUseInstruction()
                    HowToUseKeySetupSection(viewModel: viewModel)
                    Divider()
                        .padding(.vertical, Self.dividerVerticalPadding)
                    HowToUsePrivacyPolicyFullView()

                    // Consent text placed just above the button
                    Text(L10n.howtouseConsent)
                        .font(Font.craftifyBody)
                        .fontWeight(.semibold)
                        .foregroundColor(palette.primaryText())
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)

                    HowToUseAcceptButton(
                        isVerifying: viewModel.isVerifying,
                        isKeyEmpty: trimmedKey.isEmpty,
                        handleAcceptTapped: handleDoneTapped
                    )
                    .padding(.horizontal)

                    HowToUseSkipButton(handleSkipTapped: handleSkipTapped)
                        .padding(.bottom, Self.bottomPadding)
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $viewModel.showModelStep, onDismiss: handleModelStepDismiss) {
            // NavigationStack здесь только ради заголовка: сам пикер больше
            // не носит собственный стек (см. комментарий в ModelPickerView)
            NavigationStack {
                ModelPickerView(
                    selectedModel: viewModel.selectedModel,
                    availableModels: viewModel.availableModels,
                    isLoading: viewModel.isLoadingModels,
                    loadFailed: viewModel.modelsLoadFailed,
                    onSelect: { model in
                        viewModel.selectedModel = model
                        finishAndClose()
                    },
                    onRetry: {
                        Task { await viewModel.loadModels() }
                    }
                )
            }
            .environment(\.colorPalette, palette)
        }
    }

    private var trimmedKey: String {
        viewModel.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private struct HowToUseTitle: View {
        let topPadding: CGFloat
        @Environment(\.colorPalette) private var palette
        var body: some View {
            Text(L10n.howtouseTitle)
                .font(Font.craftifyTitle)
                .fontWeight(.bold)
                .foregroundColor(palette.primaryText())
                .multilineTextAlignment(.center)
                .padding(.top, topPadding)
        }
    }

    private struct HowToUseInstruction: View {
        @Environment(\.colorPalette) private var palette
        var body: some View {
            Text(L10n.howtouseInstruction)
                .font(Font.craftifyBody)
                .fontWeight(.semibold)
                .foregroundColor(palette.primaryText())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .dynamicTypeSize(.medium ... .accessibility5)
        }
    }

    /// Первичная настройка: провайдер и API-ключ прямо на экране согласия
    private struct HowToUseKeySetupSection: View {
        @ObservedObject var viewModel: HowToUseViewModel
        @Environment(\.colorPalette) private var palette
        var body: some View {
            VStack(alignment: .leading, spacing: FormStyleConstants.sectionSpacing) {
                HStack {
                    Text(LocalizedStringKey(L10n.settingsLlmProvider))
                        .font(.craftifyBody)
                        .fontWeight(.bold)
                        .foregroundColor(palette.primaryText())
                    Spacer()
                    Picker(L10n.settingsLlmProvider, selection: $viewModel.selectedProvider) {
                        ForEach(LLMProvider.allCases, id: \.rawValue) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                SecureField(L10n.settingsLlmApiKey, text: $viewModel.apiKey)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(L10n.settingsLlmApiKey)
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(palette.destructive())
                        .font(.craftifyFootnote)
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal)
        }
    }

    /// Явный путь без ключа: только согласие, настройка откладывается
    private struct HowToUseSkipButton: View {
        var handleSkipTapped: () -> Void
        @Environment(\.colorPalette) private var palette
        var body: some View {
            Button(action: handleSkipTapped) {
                Text(L10n.howtouseSetUpLater)
                    .font(Font.craftifyFootnote)
                    .fontWeight(.regular)
                    .foregroundColor(palette.secondaryText())
            }
            .accessibilityLabel(L10n.howtouseSetUpLater)
            .accessibilityIdentifier("howtouse_skip_button")
        }
    }

    /// Privacy policy text collapsed behind a disclosure to keep the screen focused
    private struct HowToUsePrivacyPolicyFullView: View {
        @Environment(\.colorPalette) private var palette
        var body: some View {
            DisclosureGroup(L10n.privacyPolicyTitle) {
                Text(L10n.privacyPolicyFull)
                    .font(.body)
                    .foregroundColor(palette.primaryText())
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .dynamicTypeSize(.small ... .accessibility5)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("privacyPolicyText")
            }
            .padding(.horizontal)
        }
    }

    private struct HowToUseAcceptButton: View {
        var isVerifying: Bool
        var isKeyEmpty: Bool
        var handleAcceptTapped: () -> Void
        @Environment(\.colorPalette) private var palette
        var body: some View {
            Button(action: handleAcceptTapped) {
                if isVerifying {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(L10n.howtouseDone)
                        .font(Font.craftifyBody)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(palette.primaryButtonText())
                }
            }
            .accessibilityLabel(L10n.howtouseDone)
            .buttonStyle(CraftifyPrimaryButtonStyle())
            .disabled(isVerifying || isKeyEmpty)
        }
    }

    /// Инициализация с менеджером согласия
    /// - Parameter consentManager: Менеджер согласия (по умолчанию — production)
    public init(consentManager: ConsentManaging = ConsentManager(), onConsent: (() -> Void)? = nil) {
        self._viewModel = ObservedObject(wrappedValue: HowToUseViewModel(consentManager: consentManager))
        self.onConsent = onConsent
    }

    private func handleDoneTapped() {
        Task { @MainActor in
            // Успешная проверка открывает шаг выбора модели (sheet);
            // онбординг завершается в finishAndClose
            _ = await viewModel.submitKey()
        }
    }

    private func handleSkipTapped() {
        viewModel.skipKeySetup()
        onConsent?()
    }

    /// Закрытие шага модели любым способом (выбор или свайп) завершает онбординг
    private func handleModelStepDismiss() {
        guard !viewModel.consentGiven else { return }
        finishAndClose()
    }

    private func finishAndClose() {
        viewModel.finishOnboarding()
        onConsent?()
    }
}
