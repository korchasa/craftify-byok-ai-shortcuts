@testable import ShareExtension
import XCTest

final class ShareExtensionViewHeightTests: XCTestCase {
    private let screenHeight: CGFloat = 800
    private let maxHeightMultiplier: CGFloat = 0.7

    /// На iPhone расширение занимает экран целиком, а на iPad живёт в popover:
    /// там высоту задаём сами — доля экрана, а не подгонка под контент
    func testPopoverHeightIsShareOfScreen() {
        let height = ShareExtensionViewHeight.maxHeight(screenHeight: screenHeight)
        XCTAssertEqual(height, screenHeight * maxHeightMultiplier, accuracy: 1)
    }
}
