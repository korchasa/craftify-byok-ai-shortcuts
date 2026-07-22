import SwiftUI
import XCTest

final class FontCraftifyTests: XCTestCase {
    /// Шрифты Craftify должны быть относительными к текстовым стилям,
    /// чтобы масштабироваться вместе с системным размером шрифта (Dynamic Type);
    /// на крупных экранах — более крупные стили
    func testCraftifyFontsUseTextStyles() {
        if DeviceScale.isScaledUp {
            XCTAssertEqual(Font.craftifyTitle, Font.system(.title, design: .default).weight(.semibold))
            XCTAssertEqual(Font.craftifyBody, Font.system(.title3, design: .default).weight(.semibold))
            XCTAssertEqual(Font.craftifyFootnote, Font.system(.subheadline, design: .default).weight(.semibold))
        } else {
            XCTAssertEqual(Font.craftifyTitle, Font.system(.title2, design: .default).weight(.semibold))
            XCTAssertEqual(Font.craftifyBody, Font.system(.body, design: .default).weight(.semibold))
            XCTAssertEqual(Font.craftifyFootnote, Font.system(.footnote, design: .default).weight(.semibold))
        }
    }

    /// Константы контролов должны считаться от вычисленного множителя экрана
    func testControlConstantsFollowScreenFactor() {
        XCTAssertGreaterThanOrEqual(DeviceScale.controlFactor, DeviceScale.minFactor)
        XCTAssertLessThanOrEqual(DeviceScale.controlFactor, DeviceScale.maxFactor)
        XCTAssertEqual(CraftifyButtonConstants.minButtonHeight, 44 * DeviceScale.controlFactor)
        XCTAssertEqual(CraftifyButtonConstants.cornerRadius, 20 * DeviceScale.controlFactor)
    }

    /// Формула масштаба: эталонный iPhone не растёт, планшеты растут плавно,
    /// сверхширокие экраны упираются в верхнюю границу
    func testScaleFormulaByShortSide() {
        XCTAssertEqual(DeviceScale.factor(forShortSide: 390), 1.0, accuracy: 0.001)
        XCTAssertEqual(DeviceScale.factor(forShortSide: 375), 1.0, accuracy: 0.001) // clamp снизу
        XCTAssertEqual(DeviceScale.factor(forShortSide: 744), 1.21, accuracy: 0.01) // iPad mini
        XCTAssertEqual(DeviceScale.factor(forShortSide: 834), 1.256, accuracy: 0.01) // iPad 11"
        XCTAssertEqual(DeviceScale.factor(forShortSide: 1024), 1.336, accuracy: 0.01) // iPad 13"
        XCTAssertEqual(DeviceScale.factor(forShortSide: 4000), DeviceScale.maxFactor) // clamp сверху
        XCTAssertEqual(DeviceScale.factor(forShortSide: 0), DeviceScale.minFactor) // защита от нуля
    }
}
