import Foundation

/// Решает, когда попросить систему показать окно оценки в App Store.
///
/// Операции выполняет расширение, а оценку просит приложение, поэтому счётчик
/// успехов, день первого засчитанного успеха и версия, в которой оценку уже
/// просили, лежат в общем хранилище App Group. Обе стороны создают политику со
/// своей версией из Info.plist — у приложения и расширения она одна
/// (`MARKETING_VERSION`).
public final class ReviewRequestPolicy {
    /// Сколько успешных операций нужно, прежде чем попросить оценку
    public static let successThreshold = 3

    private static let successCountKey = "CraftifyReviewSuccessCount"
    private static let requestedVersionKey = "CraftifyReviewRequestedVersion"
    private static let firstSuccessDateKey = "CraftifyReviewFirstSuccessDate"
    private static let shortVersionKey = "CFBundleShortVersionString"

    private let userDefaults: UserDefaults
    private let appVersion: String
    private let now: () -> Date
    private let calendar: Calendar

    /// Число успешных операций, засчитанных с последней просьбы об оценке
    public var successCount: Int {
        userDefaults.integer(forKey: Self.successCountKey)
    }

    /// Момент первого успеха, засчитанного к текущей просьбе; nil — успехов ещё не было
    public var firstSuccessDate: Date? {
        userDefaults.object(forKey: Self.firstSuccessDateKey) as? Date
    }

    private var requestedVersion: String? {
        userDefaults.string(forKey: Self.requestedVersionKey)
    }

    /// - Parameters:
    ///   - userDefaults: хранилище App Group, общее у приложения и расширения
    ///   - appVersion: маркетинговая версия запущенного бандла
    ///   - now: текущий момент; тесты подставляют свои часы
    ///   - calendar: календарь, по которому сравниваются дни
    public init(
        userDefaults: UserDefaults,
        appVersion: String,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.userDefaults = userDefaults
        self.appVersion = appVersion
        self.now = now
        self.calendar = calendar
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
    /// успехи не копятся: следующая версия начинает счёт заново. Первый
    /// засчитанный успех запоминает свой момент — в его день оценку не просят.
    public func recordSuccess() {
        // [REF:fr:ux.review-request] — счёт успехов, один запрос на версию
        guard requestedVersion != appVersion else { return }
        if firstSuccessDate == nil {
            userDefaults.set(now(), forKey: Self.firstSuccessDateKey)
        }
        userDefaults.set(successCount + 1, forKey: Self.successCountKey)
    }

    /// Можно ли сейчас попросить оценку, а если нельзя — почему.
    ///
    /// Установка, где счётчик набрали раньше, чем появился день первого успеха,
    /// получает этим днём сегодняшний: так её не спросят в день обновления.
    /// Поэтому чтение может записать этот день в хранилище.
    public func reviewDecision() -> ReviewDecision {
        // [REF:fr:ux.review-request] — порог, версия и не в первый день
        if requestedVersion == appVersion {
            return .alreadyAskedInThisVersion
        }
        let count = successCount
        let firstDay: Date
        if let stored = firstSuccessDate {
            firstDay = stored
        } else if count > 0 {
            firstDay = now()
            userDefaults.set(firstDay, forKey: Self.firstSuccessDateKey)
        } else {
            return .tooFewSuccesses
        }
        if count < Self.successThreshold {
            return .tooFewSuccesses
        }
        if calendar.isDate(firstDay, inSameDayAs: now()) {
            return .firstDayOfUse
        }
        return .due
    }

    /// Пора ли попросить оценку: набралось нужное число успехов, в этой версии
    /// оценку ещё не просили, и сегодня не день первого успеха
    public func shouldRequestReview() -> Bool {
        reviewDecision() == .due
    }

    /// Запоминает, что в этой версии оценку уже просили, и закрывает цикл:
    /// обнуляет счётчик и забывает день первого успеха
    public func markReviewRequested() {
        userDefaults.set(appVersion, forKey: Self.requestedVersionKey)
        userDefaults.set(0, forKey: Self.successCountKey)
        userDefaults.removeObject(forKey: Self.firstSuccessDateKey)
    }

    deinit {}
}
