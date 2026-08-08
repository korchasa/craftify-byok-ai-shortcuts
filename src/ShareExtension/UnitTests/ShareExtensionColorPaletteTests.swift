import SwiftUI
import XCTest

/// Тесты для палитр ShareExtension
public final class ShareExtensionColorPaletteTests: XCTestCase {
    override public func setUp() {
        super.setUp()
    }

    override public func tearDown() {
        super.tearDown()
    }

    public func testLightPaletteColors() {
        let palette = LightShareExtensionColorPalette()
        XCTAssertEqual(palette.background(), Color(hex: "#ffffff"))
        XCTAssertEqual(palette.backdrop(), Color(hex: "#f2f2f7"))
        XCTAssertEqual(palette.primaryText(), Color(hex: "#000000"))
        XCTAssertEqual(palette.secondaryText(), Color(hex: "#8e8e93"))
        XCTAssertEqual(palette.primaryButton(), Color(hex: "#ffd166"))
        XCTAssertEqual(palette.primaryButtonText(), Color(hex: "#17171c"))
        XCTAssertEqual(palette.secondaryButton(), Color(hex: "#83d483"))
        XCTAssertEqual(palette.secondaryButtonText(), Color(hex: "#17171c"))
        XCTAssertEqual(palette.destructive(), Color(hex: "#ef476f"))
        XCTAssertEqual(palette.link(), Color(hex: "#88cce2"))
    }

    public func testDarkPaletteColors() {
        let palette = DarkShareExtensionColorPalette()
        XCTAssertEqual(palette.background(), Color(hex: "#17171c"))
        XCTAssertEqual(palette.backdrop(), Color(hex: "#000000"))
        XCTAssertEqual(palette.primaryText(), Color(hex: "#ffffff"))
        XCTAssertEqual(palette.secondaryText(), Color(hex: "#8e8e93"))
        XCTAssertEqual(palette.primaryButton(), Color(hex: "#ffd166"))
        XCTAssertEqual(palette.primaryButtonText(), Color(hex: "#17171c"))
        XCTAssertEqual(palette.secondaryButton(), Color(hex: "#83d483"))
        XCTAssertEqual(palette.secondaryButtonText(), Color(hex: "#17171c"))
        XCTAssertEqual(palette.destructive(), Color(hex: "#ef476f"))
        XCTAssertEqual(palette.link(), Color(hex: "#88cce2"))
    }

    public func testPaletteConstants() {
        let palette = LightShareExtensionColorPalette()
        XCTAssertEqual(palette.circleSize, ColorPaletteConstants.circleSize)
        XCTAssertEqual(palette.circleSpacing, 12)
        XCTAssertEqual(palette.borderWidth, 3)
        XCTAssertEqual(palette.verticalSpacing, 8)
        XCTAssertEqual(palette.bottomPadding, 4)
    }

    deinit {}
}
