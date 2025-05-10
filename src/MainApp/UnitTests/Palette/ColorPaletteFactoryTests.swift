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
        XCTAssertEqual(palette.background(), Color.white)
        XCTAssertEqual(palette.primaryButtonText(), Color.black)
        XCTAssertEqual(palette.primaryButton(), Color.white)
        XCTAssertEqual(palette.secondaryButtonText(), Color.black)
        XCTAssertEqual(palette.secondaryButton(), Color.white)
    }

    /// Проверяет цвета тёмной палитры
    public func testDarkPaletteColors() {
        let palette = DarkMainAppColorPalette()
        let darkBg = Color(red: 0.09, green: 0.09, blue: 0.11)
        XCTAssertEqual(palette.background(), darkBg)
        XCTAssertEqual(palette.primaryButtonText(), Color.white)
        XCTAssertEqual(palette.primaryButton(), darkBg)
        XCTAssertEqual(palette.secondaryButtonText(), Color.white)
        XCTAssertEqual(palette.secondaryButton(), darkBg)
    }
}
