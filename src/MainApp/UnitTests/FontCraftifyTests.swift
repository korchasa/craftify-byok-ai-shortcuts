import SwiftUI
import XCTest

final class FontCraftifyTests: XCTestCase {
    /// Шрифты Craftify должны быть относительными к текстовым стилям,
    /// чтобы масштабироваться вместе с системным размером шрифта (Dynamic Type)
    func testCraftifyFontsUseTextStyles() {
        XCTAssertEqual(Font.craftifyTitle, Font.system(.title2, design: .default).weight(.semibold))
        XCTAssertEqual(Font.craftifyBody, Font.system(.body, design: .default).weight(.semibold))
        XCTAssertEqual(Font.craftifyFootnote, Font.system(.footnote, design: .default).weight(.semibold))
    }
}
