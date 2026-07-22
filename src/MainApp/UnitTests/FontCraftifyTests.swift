import SwiftUI
import XCTest

final class FontCraftifyTests: XCTestCase {
    /// Шрифты Craftify должны быть относительными к текстовым стилям,
    /// чтобы масштабироваться вместе с системным размером шрифта (Dynamic Type);
    /// на iPad — более крупные стили, чтобы контролы не сохраняли iPhone-размеры
    func testCraftifyFontsUseTextStyles() {
        if DeviceScale.isPad {
            XCTAssertEqual(Font.craftifyTitle, Font.system(.title, design: .default).weight(.semibold))
            XCTAssertEqual(Font.craftifyBody, Font.system(.title3, design: .default).weight(.semibold))
            XCTAssertEqual(Font.craftifyFootnote, Font.system(.subheadline, design: .default).weight(.semibold))
        } else {
            XCTAssertEqual(Font.craftifyTitle, Font.system(.title2, design: .default).weight(.semibold))
            XCTAssertEqual(Font.craftifyBody, Font.system(.body, design: .default).weight(.semibold))
            XCTAssertEqual(Font.craftifyFootnote, Font.system(.footnote, design: .default).weight(.semibold))
        }
    }

    /// Множитель контролов должен увеличивать размеры только на iPad
    func testControlFactorMatchesIdiom() {
        if DeviceScale.isPad {
            XCTAssertGreaterThan(DeviceScale.controlFactor, 1.0)
        } else {
            XCTAssertEqual(DeviceScale.controlFactor, 1.0)
        }
        XCTAssertEqual(CraftifyButtonConstants.minButtonHeight, 44 * DeviceScale.controlFactor)
        XCTAssertEqual(CraftifyButtonConstants.cornerRadius, 20 * DeviceScale.controlFactor)
    }
}
