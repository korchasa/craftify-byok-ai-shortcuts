import Foundation

/// Протокол для менеджера согласия
public protocol ConsentManaging: AnyObject {
    func getConsent() -> Bool
    func setConsent(_ value: Bool)
    func clearConsent()
}
