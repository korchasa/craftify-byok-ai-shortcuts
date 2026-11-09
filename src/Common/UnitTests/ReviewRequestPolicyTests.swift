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

    private func policy(version: String) -> ReviewRequestPolicy {
        ReviewRequestPolicy(userDefaults: userDefaults, appVersion: version)
    }

    func testRequestsReviewOnThirdSuccessOncePerVersion() {
        let policy = policy(version: "2.0.3")
        XCTAssertFalse(policy.shouldRequestReview(), "no successes yet — never at first launch")

        policy.recordSuccess()
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
        let old = policy(version: "2.0.3")
        for _ in 0 ..< ReviewRequestPolicy.successThreshold {
            old.recordSuccess()
        }
        old.markReviewRequested()

        let new = policy(version: "2.0.4")
        XCTAssertFalse(new.shouldRequestReview(), "an update alone must not trigger the prompt")
        new.recordSuccess()
        new.recordSuccess()
        XCTAssertFalse(new.shouldRequestReview())
        new.recordSuccess()
        XCTAssertTrue(new.shouldRequestReview())
    }

    func testCountIsSharedThroughTheSameDefaults() {
        // Расширение считает, приложение спрашивает: оба видят одно хранилище
        let extensionSide = policy(version: "2.0.3")
        let appSide = policy(version: "2.0.3")
        for _ in 0 ..< ReviewRequestPolicy.successThreshold {
            extensionSide.recordSuccess()
        }
        XCTAssertTrue(appSide.shouldRequestReview())
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
}
