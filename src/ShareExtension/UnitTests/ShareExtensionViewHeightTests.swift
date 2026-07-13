@testable import ShareExtension
import XCTest

final class ShareExtensionViewHeightTests: XCTestCase {
    private let screenHeight: CGFloat = 800
    private let minHeight: CGFloat = 220
    private let maxHeightMultiplier: CGFloat = 0.7

    func testHeightForZeroOperations() {
        let height = ShareExtensionViewHeight.calculate(count: 0, screenHeight: screenHeight)
        XCTAssertEqual(height, minHeight, accuracy: 1)
    }

    func testHeightForManyOperations() {
        let height = ShareExtensionViewHeight.calculate(count: 100, screenHeight: screenHeight)
        XCTAssertEqual(height, screenHeight * maxHeightMultiplier, accuracy: 1)
    }

    func testDetentGrowsWithOperationsAndResult() {
        // Нет замера (первый layout-проход) — берём высоту по количеству операций
        let fallback = ShareExtensionViewHeight.detent(
            measuredContentHeight: 0, operationsCount: 4, hasResult: false, screenHeight: screenHeight
        )
        XCTAssertEqual(fallback, ShareExtensionViewHeight.calculate(count: 4, screenHeight: screenHeight))

        // Замеренный контент растёт — detent растёт вместе с ним
        let small = ShareExtensionViewHeight.detent(
            measuredContentHeight: 300, operationsCount: 4, hasResult: false, screenHeight: screenHeight
        )
        let large = ShareExtensionViewHeight.detent(
            measuredContentHeight: 450, operationsCount: 4, hasResult: false, screenHeight: screenHeight
        )
        XCTAssertEqual(small, 300)
        XCTAssertEqual(large, 450)

        // Слишком маленький и слишком большой замеры зажимаются в допустимые границы
        let clampedMin = ShareExtensionViewHeight.detent(
            measuredContentHeight: 10, operationsCount: 0, hasResult: false, screenHeight: screenHeight
        )
        XCTAssertEqual(clampedMin, minHeight)
        let clampedMax = ShareExtensionViewHeight.detent(
            measuredContentHeight: 10_000, operationsCount: 4, hasResult: false, screenHeight: screenHeight
        )
        XCTAssertEqual(clampedMax, screenHeight * maxHeightMultiplier)

        // Показ результата разворачивает шторку: кастомного detent нет (nil -> .large())
        let result = ShareExtensionViewHeight.detent(
            measuredContentHeight: 300, operationsCount: 4, hasResult: true, screenHeight: screenHeight
        )
        XCTAssertNil(result)
    }
}
