import XCTest

/// Нормализация значений длины резюме: канонические строки проходят как есть,
/// локализованные строки старых записей сопоставляются по цифрам
public final class SummarizeLengthsTests: XCTestCase {
    public func testCanonicalValuesPassThrough() {
        for value in SummarizeLengths.all {
            XCTAssertEqual(SummarizeLengths.normalize(value), value)
        }
    }

    public func testLocalizedLegacyValuesNormalizeByDigits() {
        XCTAssertEqual(SummarizeLengths.normalize("9\u{2013}10 sentences"), "9-10 sentences")
        XCTAssertEqual(SummarizeLengths.normalize("9\u{2013}10 предложений"), "9-10 sentences")
        XCTAssertEqual(SummarizeLengths.normalize("2\u{2013}3 предложения"), "2-3 sentences")
        XCTAssertEqual(SummarizeLengths.normalize("18\u{2013}20 Sätze"), "18-20 sentences")
    }

    public func testUnknownValueFallsBackToDefault() {
        XCTAssertEqual(SummarizeLengths.normalize(""), SummarizeLengths.defaultLength)
        XCTAssertEqual(SummarizeLengths.normalize("whatever"), SummarizeLengths.defaultLength)
        XCTAssertEqual(SummarizeLengths.normalize("7-8 sentences"), SummarizeLengths.defaultLength)
    }

    public func testDecodeInputNormalizesStoredLength() throws {
        let params = SummarizeParams(length: "9\u{2013}10 предложений")
        let data = try JSONEncoder().encode(params)
        let input = try SummarizeOperation().decodeInput(from: data)
        XCTAssertEqual(input.length, "9-10 sentences")
    }
}
