@testable import ShareExtension
import XCTest

final class ShareExtensionViewHeightTests: XCTestCase {
    func testHeightForZeroOperations() {
        let height = ShareExtensionViewHeight.calculate(count: 0)
        let minHeight: CGFloat = 220
        XCTAssertEqual(height, minHeight, accuracy: 1)
    }

    func testHeightForOneOperation() {
        let height = ShareExtensionViewHeight.calculate(count: 1)
        let minHeight: CGFloat = 220
        XCTAssertEqual(height, minHeight, accuracy: 1)
    }

    func testHeightForTwoOperations() {
        let height = ShareExtensionViewHeight.calculate(count: 2)
        let minHeight: CGFloat = 220
        XCTAssertEqual(height, minHeight, accuracy: 1)
    }

    func testHeightForManyOperations() {
        let height = ShareExtensionViewHeight.calculate(count: 100)
        let maxHeight = UIScreen.main.bounds.height * 0.7
        XCTAssertEqual(height, maxHeight, accuracy: 1)
    }

    func testHeightForTypicalCase() {
        let height = ShareExtensionViewHeight.calculate(count: 6)
        let minHeight: CGFloat = 220
        let maxHeight = UIScreen.main.bounds.height * 0.7
        XCTAssertGreaterThanOrEqual(height, minHeight)
        XCTAssertLessThanOrEqual(height, maxHeight)
    }
}
