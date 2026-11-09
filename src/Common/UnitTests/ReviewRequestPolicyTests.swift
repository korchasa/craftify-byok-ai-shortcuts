import XCTest

final class ReviewRequestPolicyTests: XCTestCase {
    private var suiteName = ""
    private var userDefaults = UserDefaults.standard

    override func setUp() {
        super.setUp()
        suiteName = "ReviewRequestPolicyTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testRequestsReviewOnThirdSuccessOncePerVersion() {
        // Успехи копятся вчера, спрашиваем сегодня: правило первого дня здесь ни при чём
        let clock = Clock(Self.date(9, 10))
        let policy = policy(version: "2.0.3", clock: clock)
        XCTAssertFalse(policy.shouldRequestReview(), "no successes yet — never at first launch")

        policy.recordSuccess()
        clock.now = Self.date(10, 10)
        XCTAssertFalse(policy.shouldRequestReview())
        policy.recordSuccess()
        XCTAssertFalse(policy.shouldRequestReview())
        policy.recordSuccess()
        XCTAssertTrue(policy.shouldRequestReview())

        policy.markReviewRequested()
        XCTAssertFalse(policy.shouldRequestReview())

        // Успехи в той же версии после просьбы не копятся к следующей
        for _ in 0 ..< ReviewRequestPolicy.successThreshold + 1 {
            policy.recordSuccess()
        }
        XCTAssertFalse(policy.shouldRequestReview())
        XCTAssertEqual(policy.successCount, 0)
    }

    func testLaterVersionNeedsThreeNewSuccesses() {
        let clock = Clock(Self.date(1, 10))
        let old = policy(version: "2.0.3", clock: clock)
        for _ in 0 ..< ReviewRequestPolicy.successThreshold {
            old.recordSuccess()
        }
        old.markReviewRequested()

        let new = policy(version: "2.0.4", clock: clock)
        XCTAssertFalse(new.shouldRequestReview(), "an update alone must not trigger the prompt")
        new.recordSuccess()
        clock.now = Self.date(5, 10)
        new.recordSuccess()
        XCTAssertFalse(new.shouldRequestReview())
        new.recordSuccess()
        XCTAssertTrue(new.shouldRequestReview())
    }

    func testCountIsSharedThroughTheSameDefaults() {
        // Расширение считает, приложение спрашивает: оба видят одно хранилище
        let extensionSide = policy(version: "2.0.3", clock: Clock(Self.date(8, 10)))
        let appSide = policy(version: "2.0.3", clock: Clock(Self.date(9, 10)))
        for _ in 0 ..< ReviewRequestPolicy.successThreshold {
            extensionSide.recordSuccess()
        }
        XCTAssertTrue(appSide.shouldRequestReview(), "the first day the extension recorded is seen by the app")
        appSide.markReviewRequested()
        XCTAssertFalse(extensionSide.shouldRequestReview())
    }

    func testAppVersionIsReadFromShortVersionString() {
        XCTAssertNil(ReviewRequestPolicy.appVersion(infoDictionary: [:]))
        XCTAssertNil(ReviewRequestPolicy.appVersion(infoDictionary: ["CFBundleShortVersionString": ""]))
        XCTAssertEqual(
            ReviewRequestPolicy.appVersion(infoDictionary: ["CFBundleShortVersionString": "2.0.3"]),
            "2.0.3"
        )
    }

    // MARK: - Не в первый день использования

    /// Календарь с фиксированной зоной: граница суток не зависит от машины, где идут тесты
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Sofia") ?? .current
        return calendar
    }()

    /// Момент в зоне тестового календаря
    private static func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        let components = DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute)
        return calendar.date(from: components) ?? Date(timeIntervalSince1970: 0)
    }

    /// Политика, которая видит «сейчас» таким, какое лежит в `clock`
    private func policy(version: String = "2.0.3", clock: Clock) -> ReviewRequestPolicy {
        ReviewRequestPolicy(userDefaults: userDefaults, appVersion: version, now: { clock.now }, calendar: Self.calendar)
    }

    /// Изменяемые часы для тестов
    private final class Clock {
        var now: Date
        init(_ now: Date) {
            self.now = now
        }

        deinit {}
    }

    func testNotDueOnTheDayOfTheFirstSuccess() {
        let clock = Clock(Self.date(9, 10))
        let policy = policy(clock: clock)
        for _ in 0 ..< ReviewRequestPolicy.successThreshold {
            policy.recordSuccess()
        }
        XCTAssertEqual(policy.reviewDecision(), .firstDayOfUse, "three successes on the first day are not enough")
        XCTAssertFalse(policy.shouldRequestReview())

        clock.now = Self.date(9, 23, 59)
        XCTAssertEqual(policy.reviewDecision(), .firstDayOfUse)

        clock.now = Self.date(10, 0, 1)
        XCTAssertEqual(policy.reviewDecision(), .due, "the next calendar day the request is due")
        XCTAssertTrue(policy.shouldRequestReview())
    }

    func testFirstSuccessDayIsTheFirstCountedSuccessNotTheLatest() {
        let clock = Clock(Self.date(8, 22))
        let policy = policy(clock: clock)
        policy.recordSuccess()
        XCTAssertEqual(policy.firstSuccessDate, Self.date(8, 22))

        clock.now = Self.date(9, 9)
        policy.recordSuccess()
        policy.recordSuccess()
        XCTAssertEqual(policy.firstSuccessDate, Self.date(8, 22), "later successes do not move the first day")
        XCTAssertEqual(policy.reviewDecision(), .due)
    }

    func testDecisionNamesWhatIsMissing() {
        let clock = Clock(Self.date(9, 10))
        let policy = policy(clock: clock)
        XCTAssertEqual(policy.reviewDecision(), .tooFewSuccesses)
        for _ in 0 ..< ReviewRequestPolicy.successThreshold {
            policy.recordSuccess()
        }
        clock.now = Self.date(11, 10)
        XCTAssertEqual(policy.reviewDecision(), .due)
        policy.markReviewRequested()
        XCTAssertEqual(policy.reviewDecision(), .alreadyAskedInThisVersion)
    }

    func testInstallWithCountButNoFirstDayIsNotAskedTheSameDay() {
        // Установка, где счётчик набрали до появления ключа первого дня
        userDefaults.set(3, forKey: "CraftifyReviewSuccessCount")
        let clock = Clock(Self.date(9, 18))
        let policy = policy(clock: clock)

        XCTAssertEqual(policy.reviewDecision(), .firstDayOfUse, "a missing first day counts as today")
        XCTAssertEqual(policy.firstSuccessDate, Self.date(9, 18), "and is recorded on that first read")

        clock.now = Self.date(10, 8)
        XCTAssertEqual(policy.reviewDecision(), .due)
    }

    func testEmptyInstallRecordsNoFirstDayOnRead() {
        let policy = policy(clock: Clock(Self.date(9, 18)))
        XCTAssertEqual(policy.reviewDecision(), .tooFewSuccesses)
        XCTAssertNil(policy.firstSuccessDate, "nothing counted yet, so there is no first day")
    }

    func testNextVersionMeasuresItsFirstDayAnew() {
        let clock = Clock(Self.date(1, 10))
        let old = policy(version: "2.0.3", clock: clock)
        for _ in 0 ..< ReviewRequestPolicy.successThreshold {
            old.recordSuccess()
        }
        clock.now = Self.date(2, 10)
        XCTAssertEqual(old.reviewDecision(), .due)
        old.markReviewRequested()
        XCTAssertNil(old.firstSuccessDate, "the request closes the cycle together with the counter")

        let new = policy(version: "2.0.4", clock: clock)
        for _ in 0 ..< ReviewRequestPolicy.successThreshold {
            new.recordSuccess()
        }
        XCTAssertEqual(new.reviewDecision(), .firstDayOfUse)
        clock.now = Self.date(3, 10)
        XCTAssertEqual(new.reviewDecision(), .due)
    }
}
