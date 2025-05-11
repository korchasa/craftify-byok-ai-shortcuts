@testable import MainApp
import SwiftUI
import XCTest

/// Тесты для ColorPaletteFactory и палитр MainApp
public final class ColorPaletteFactoryTests: XCTestCase {
    deinit {}
    /// Проверяет, что фабрика возвращает LightMainAppColorPalette для .light
    public func testFactoryReturnsLightPaletteForLightScheme() {
        let palette = ColorPaletteFactory.palette(for: .light)
        // swiftlint:disable:next prefer_nimble
        XCTAssertTrue(palette is LightMainAppColorPalette)
    }

    /// Проверяет, что фабрика возвращает DarkMainAppColorPalette для .dark
    public func testFactoryReturnsDarkPaletteForDarkScheme() {
        let palette = ColorPaletteFactory.palette(for: .dark)
        // swiftlint:disable:next prefer_nimble
        XCTAssertTrue(palette is DarkMainAppColorPalette)
    }

    /// Проверяет цвета светлой палитры
    public func testLightPaletteColors() {
        let palette = LightMainAppColorPalette()
        XCTAssertEqual(palette.background(), Color(hex: "#ffffff"))
        XCTAssertEqual(palette.primaryText(), Color(hex: "#17171c"))
        XCTAssertEqual(palette.secondaryText(), Color(hex: "#8e8e93"))
        XCTAssertEqual(palette.primaryButton(), Color(hex: "#ffd166"))
        XCTAssertEqual(palette.primaryButtonText(), Color(hex: "#17171c"))
        XCTAssertEqual(palette.secondaryButton(), Color(hex: "#83d483"))
        XCTAssertEqual(palette.secondaryButtonText(), Color(hex: "#17171c"))
        XCTAssertEqual(palette.destructive(), Color(hex: "#ef476f"))
        XCTAssertEqual(palette.link(), Color(hex: "#17171c"))
    }

    /// Проверяет цвета тёмной палитры
    public func testDarkPaletteColors() {
        let palette = DarkMainAppColorPalette()
        XCTAssertEqual(palette.background(), Color(hex: "#17171c"))
        XCTAssertEqual(palette.primaryText(), Color(hex: "#ffffff"))
        XCTAssertEqual(palette.secondaryText(), Color(hex: "#8e8e93"))
        XCTAssertEqual(palette.primaryButton(), Color(hex: "#ffd166"))
        XCTAssertEqual(palette.primaryButtonText(), Color(hex: "#17171c"))
        XCTAssertEqual(palette.secondaryButton(), Color(hex: "#83d483"))
        XCTAssertEqual(palette.secondaryButtonText(), Color(hex: "#17171c"))
        XCTAssertEqual(palette.destructive(), Color(hex: "#ef476f"))
        XCTAssertEqual(palette.link(), Color(hex: "#17171c"))
    }
}
