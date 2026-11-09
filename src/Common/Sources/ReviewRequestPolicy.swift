import Foundation

/// Решает, когда попросить систему показать окно оценки в App Store.
///
/// Операции выполняет расширение, а оценку просит приложение, поэтому счётчик
/// успехов и версия, в которой оценку уже просили, лежат в общем хранилище
/// App Group. Обе стороны создают политику со своей версией из Info.plist —
/// у приложения и расширения она одна (`MARKETING_VERSION`).
public final class ReviewRequestPolicy {
    /// Сколько успешных операций нужно, прежде чем попросить оценку
    public static let successThreshold = 3

    private static let successCountKey = "CraftifyReviewSuccessCount"
    private static let requestedVersionKey = "CraftifyReviewRequestedVersion"
    private static let shortVersionKey = "CFBundleShortVersionString"

    private let userDefaults: UserDefaults
    private let appVersion: String

    /// Число успешных операций, засчитанных с последней просьбы об оценке
    public var successCount: Int {
        userDefaults.integer(forKey: Self.successCountKey)
    }

    private var requestedVersion: String? {
        userDefaults.string(forKey: Self.requestedVersionKey)
    }

    /// - Parameters:
    ///   - userDefaults: хранилище App Group, общее у приложения и расширения
    ///   - appVersion: маркетинговая версия запущенного бандла
    public init(userDefaults: UserDefaults, appVersion: String) {
        self.userDefaults = userDefaults
        self.appVersion = appVersion
    }

    /// Маркетинговая версия из словаря Info.plist; nil, если её там нет
    /// - Parameter infoDictionary: словарь Info.plist бандла
    public static func appVersion(infoDictionary: [String: Any]) -> String? {
        guard let version = infoDictionary[shortVersionKey] as? String, !version.isEmpty else {
            return nil
        }
        return version
    }

    /// Маркетинговая версия запущенного бандла. Её подставляет сборка, как и
    /// идентификатор App Group, поэтому её отсутствие — сломанная сборка.
    /// - Parameter bundle: бандл приложения или расширения
    public static func appVersion(of bundle: Bundle) -> String {
        guard let version = appVersion(infoDictionary: bundle.infoDictionary ?? [:]) else {
            fatalError("\(shortVersionKey) отсутствует в Info.plist бандла \(bundle.bundleIdentifier ?? "?")")
        }
        return version
    }

    /// Засчитывает успешную операцию. В версии, где оценку уже просили,
    /// успехи не копятся: следующая версия начинает счёт заново.
    public func recordSuccess() {
        // [REF:fr:ux.review-request] — счёт успехов, один запрос на версию
        guard requestedVersion != appVersion else { return }
        userDefaults.set(successCount + 1, forKey: Self.successCountKey)
    }

    /// Пора ли попросить оценку: набралось нужное число успехов, а в этой
    /// версии оценку ещё не просили
    public func shouldRequestReview() -> Bool {
        successCount >= Self.successThreshold && requestedVersion != appVersion
    }

    /// Запоминает, что в этой версии оценку уже просили, и обнуляет счётчик
    public func markReviewRequested() {
        userDefaults.set(appVersion, forKey: Self.requestedVersionKey)
        userDefaults.set(0, forKey: Self.successCountKey)
    }

    deinit {}
}
