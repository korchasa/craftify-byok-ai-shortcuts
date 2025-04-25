import Common
import Foundation
import SwiftUI

/// ViewModel для HowToUseView: хранит состояние чекбокса и сохраняет согласие
public final class HowToUseViewModel: ObservableObject {
    @Published public var consentGiven: Bool
    private let consentManager: ConsentManaging

    /// Инициализация с менеджером согласия
    /// - Parameter consentManager: Менеджер согласия
    public init(consentManager: ConsentManaging) {
        self.consentManager = consentManager
        self.consentGiven = consentManager.getConsent()
    }

    /// Сохраняет согласие пользователя
    public func saveConsent() {
        consentManager.setConsent(consentGiven)
    }

    deinit {
        // Очистка ресурсов не требуется
    }
}
