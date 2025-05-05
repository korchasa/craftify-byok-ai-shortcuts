import Foundation

public final class AppState: ObservableObject {
    @Published public var isConsentGiven: Bool
    private let consentManager: ConsentManaging

    public init(consentManager: ConsentManaging = ConsentManager()) {
        self.consentManager = consentManager
        self.isConsentGiven = consentManager.getConsent()
    }

    public func setConsentGiven(_ value: Bool) {
        consentManager.setConsent(value)
        isConsentGiven = value
    }

    deinit {
        // Очистка ресурсов не требуется
    }
}
