@testable import ShareExtension
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
        XCTAssertEqual(palette.background(), Color.white)
        XCTAssertEqual(palette.primaryText(), Color.black)
        XCTAssertEqual(palette.secondaryText(), Color(white: ColorPaletteConstants.secondaryTextWhite))
        XCTAssertEqual(palette.primaryButton(), Color(red: ColorPaletteConstants.primaryRed, green: ColorPaletteConstants.primaryGreen, blue: ColorPaletteConstants.primaryBlue))
        XCTAssertEqual(palette.primaryButtonText(), Color(hex: "#17171c"))
        XCTAssertEqual(palette.secondaryButton(), Color(red: ColorPaletteConstants.secondaryRed, green: ColorPaletteConstants.secondaryGreen, blue: ColorPaletteConstants.secondaryBlue))
        XCTAssertEqual(palette.secondaryButtonText(), Color(hex: "#17171c"))
        XCTAssertEqual(palette.destructive(), Color(red: ColorPaletteConstants.destructiveLightRed, green: ColorPaletteConstants.destructiveLightGreen, blue: ColorPaletteConstants.destructiveLightBlue))
        XCTAssertEqual(palette.link(), Color(red: ColorPaletteConstants.linkLightRed, green: ColorPaletteConstants.linkLightGreen, blue: ColorPaletteConstants.linkLightBlue))
    }

    public func testDarkPaletteColors() {
        let palette = DarkShareExtensionColorPalette()
        XCTAssertEqual(palette.background(), Color(red: ColorPaletteConstants.backgroundDarkRed, green: ColorPaletteConstants.backgroundDarkGreen, blue: ColorPaletteConstants.backgroundDarkBlue))
        XCTAssertEqual(palette.primaryText(), Color.white)
        XCTAssertEqual(palette.secondaryText(), Color(red: ColorPaletteConstants.secondaryTextRed, green: ColorPaletteConstants.secondaryTextGreen, blue: ColorPaletteConstants.secondaryTextBlue))
        XCTAssertEqual(palette.primaryButton(), Color(red: ColorPaletteConstants.primaryRed, green: ColorPaletteConstants.primaryGreen, blue: ColorPaletteConstants.primaryBlue))
        XCTAssertEqual(palette.primaryButtonText(), Color(hex: "#17171c"))
        XCTAssertEqual(palette.secondaryButton(), Color(red: ColorPaletteConstants.secondaryRed, green: ColorPaletteConstants.secondaryGreen, blue: ColorPaletteConstants.secondaryBlue))
        XCTAssertEqual(palette.secondaryButtonText(), Color(hex: "#17171c"))
        XCTAssertEqual(palette.destructive(), Color(red: ColorPaletteConstants.destructiveRed, green: ColorPaletteConstants.destructiveGreen, blue: ColorPaletteConstants.destructiveBlue))
        XCTAssertEqual(palette.link(), Color(red: ColorPaletteConstants.linkRed, green: ColorPaletteConstants.linkGreen, blue: ColorPaletteConstants.linkBlue))
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
