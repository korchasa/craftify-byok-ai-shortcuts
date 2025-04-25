import Foundation

/// In-memory stub для ConsentManaging (тесты)
public final class ConsentManagerStub: ConsentManaging {
    private var consent: Bool = false

    public init() {}

    /// Получить согласие пользователя (in-memory)
    public func getConsent() -> Bool {
        consent
    }

    /// Установить согласие пользователя (in-memory)
    public func setConsent(_ value: Bool) {
        consent = value
    }

    /// Очистить согласие пользователя (in-memory)
    public func clearConsent() {
        consent = false
    }

    deinit {
        // Очистка ресурсов не требуется
    }
}
