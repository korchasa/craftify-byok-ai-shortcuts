@testable import MainApp
import XCTest

/// Когда главный экран начинает отсчёт до просьбы об оценке
final class ReviewPromptTriggerTests: XCTestCase {
    func testNothingIsPendingAtLaunchOrOnReturnToForeground() {
        var trigger = ReviewPromptTrigger()
        XCTAssertNil(trigger.countdown, "opening the app alone never starts a countdown")

        trigger.foregroundChanged(isActive: false)
        trigger.foregroundChanged(isActive: true)
        XCTAssertNil(trigger.countdown, "coming back to the foreground never starts one either")
    }

    func testClosingATaskScreenStartsTheCountdown() {
        var trigger = ReviewPromptTrigger()
        trigger.taskSheetChanged(isShown: true)
        XCTAssertNil(trigger.countdown, "nothing is asked while a task screen is open")

        trigger.taskSheetChanged(isShown: false)
        let countdown = trigger.countdown
        XCTAssertNotNil(countdown)
        if let countdown {
            XCTAssertTrue(trigger.mayAsk(afterCountdown: countdown))
        }
    }

    func testOpeningAnotherTaskScreenCancelsTheCountdown() {
        var trigger = ReviewPromptTrigger()
        trigger.taskSheetChanged(isShown: true)
        trigger.taskSheetChanged(isShown: false)
        let first = trigger.countdown

        trigger.taskSheetChanged(isShown: true)
        XCTAssertNil(trigger.countdown)
        if let first {
            XCTAssertFalse(trigger.mayAsk(afterCountdown: first), "a stale countdown must not ask over the new screen")
        }

        trigger.taskSheetChanged(isShown: false)
        XCTAssertNotNil(trigger.countdown)
        XCTAssertNotEqual(trigger.countdown, first, "each closing starts a fresh countdown")
    }

    func testLeavingTheForegroundCancelsTheCountdown() {
        var trigger = ReviewPromptTrigger()
        trigger.taskSheetChanged(isShown: true)
        trigger.taskSheetChanged(isShown: false)
        let countdown = trigger.countdown

        trigger.foregroundChanged(isActive: false)
        XCTAssertNil(trigger.countdown)
        trigger.foregroundChanged(isActive: true)
        XCTAssertNil(trigger.countdown, "returning does not resume the cancelled countdown")
        if let countdown {
            XCTAssertFalse(trigger.mayAsk(afterCountdown: countdown))
        }
    }

    func testRepeatedClosedStateStartsNoCountdown() {
        var trigger = ReviewPromptTrigger()
        trigger.taskSheetChanged(isShown: false)
        XCTAssertNil(trigger.countdown, "only a screen that was open can be closed")
    }

    func testClosingInTheBackgroundStartsNoCountdown() {
        var trigger = ReviewPromptTrigger()
        trigger.taskSheetChanged(isShown: true)
        trigger.foregroundChanged(isActive: false)
        trigger.taskSheetChanged(isShown: false)
        XCTAssertNil(trigger.countdown)
    }
}
