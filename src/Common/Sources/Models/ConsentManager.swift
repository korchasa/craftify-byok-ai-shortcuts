import Foundation

/// Менеджер согласия пользователя (UserDefaults AppGroup)
public final class ConsentManager: ConsentManaging {
    private let userDefaults: UserDefaults
    private let consentKey = "CraftifyConsentGiven"

    /// Инициализация менеджера согласия
    /// - Parameter appGroupSuiteName: Suite name App Group (по умолчанию — группа этой сборки)
    public init(appGroupSuiteName: String = AppGroup.identifier) {
        guard let appGroupDefaults = UserDefaults(suiteName: appGroupSuiteName) else {
            fatalError("App Group UserDefaults not found")
        }
        self.userDefaults = appGroupDefaults
    }

    /// Получить согласие пользователя
    public func getConsent() -> Bool {
        userDefaults.bool(forKey: consentKey)
    }

    /// Установить согласие пользователя
    public func setConsent(_ value: Bool) {
        userDefaults.set(value, forKey: consentKey)
    }

    /// Очистить согласие пользователя
    public func clearConsent() {
        userDefaults.removeObject(forKey: consentKey)
    }

    deinit {
        // Очистка ресурсов не требуется
    }
}
