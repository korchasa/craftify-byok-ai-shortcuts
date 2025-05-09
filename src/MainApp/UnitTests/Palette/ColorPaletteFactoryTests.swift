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
        // swiftlint:disable:next prefer_nimble
        XCTAssertEqual(palette.background(), Color.white)
        // swiftlint:disable:next prefer_nimble
        XCTAssertEqual(palette.primaryButtonText(), Color.white)
        // ...добавить проверки для других методов
    }

    /// Проверяет цвета тёмной палитры
    public func testDarkPaletteColors() {
        let palette = DarkMainAppColorPalette()
        // swiftlint:disable:next prefer_nimble
        XCTAssertEqual(palette.background(), Color(red: 0.09, green: 0.09, blue: 0.11))
        // swiftlint:disable:next prefer_nimble
        XCTAssertEqual(palette.primaryButtonText(), Color(red: 0.09, green: 0.09, blue: 0.11))
        // ...добавить проверки для других методов
    }
}
