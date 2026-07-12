import Foundation
import SwiftUI

/// ViewModel для HowToUseView: согласие пользователя и первичная настройка API-ключа
public final class HowToUseViewModel: ObservableObject {
    @Published public var consentGiven: Bool
    /// Введённый пользователем API-ключ (можно оставить пустым и добавить позже в настройках)
    @Published public var apiKey: String = ""
    /// Выбранный провайдер
    @Published public var selectedProvider: LLMProvider = AppSettingsManager.shared.llmProvider
    /// Идёт проверка ключа у провайдера
    @Published public var isVerifying: Bool = false
    /// Сообщение об ошибке проверки ключа
    @Published public var errorMessage: String? = nil

    private let consentManager: ConsentManaging
    private let authManager: AuthManaging
    private let verifier: APIKeyVerifying

    /// Инициализация с менеджерами
    /// - Parameters:
    ///   - consentManager: Менеджер согласия
    ///   - authManager: Менеджер API-ключа
    ///   - verifier: Проверка ключа у провайдера
    public init(
        consentManager: ConsentManaging,
        authManager: AuthManaging = AuthManager(),
        verifier: APIKeyVerifying = APIKeyVerifier()
    ) {
        self.consentManager = consentManager
        self.authManager = authManager
        self.verifier = verifier
        self.consentGiven = consentManager.getConsent()
    }

    /// Сохраняет согласие пользователя
    public func saveConsent() {
        consentManager.setConsent(consentGiven)
    }

    /// Завершает онбординг: если ключ введён — проверяет и сохраняет его вместе с провайдером,
    /// затем фиксирует согласие. Возвращает false, если провайдер отклонил ключ.
    @preconcurrency
    @MainActor
    public func completeOnboarding() async -> Bool {
        errorMessage = nil
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !key.isEmpty {
            isVerifying = true
            defer { isVerifying = false }
            if await verifier.verify(key: key, provider: selectedProvider) == .invalid {
                errorMessage = "\(localized(.errorInvalidApiKey))\n\n\(localized(.adviceCheckApiKey))"
                return false
            }
            AppSettingsManager.shared.llmProvider = selectedProvider
            try? await authManager.setAPIKey(key)
        }
        consentGiven = true
        saveConsent()
        return true
    }

    /// Локализует ключ ошибки по таблице Localizable бандла приложения
    private func localized(_ key: UserFacingErrorKey) -> String {
        key.localized(in: Bundle(for: HowToUseViewModel.self))
    }

    deinit {
        // Очистка ресурсов не требуется
    }
}
