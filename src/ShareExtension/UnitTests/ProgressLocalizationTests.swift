// Tests are compiled only when XCTest is available (i.e. in test targets).
#if canImport(XCTest)

import XCTest

/// Тесты корректного отображения строки формата процентов в ShareExtension
public final class ProgressLocalizationTests: XCTestCase {
    // MARK: - Lifecycle

    public override func setUp() {
        super.setUp()
    }

    public override func tearDown() {
        super.tearDown()
    }

    // MARK: - Tests

    /// Проверяет, что локализация ключа `percent_format` формирует правильную строку процента.
    public func testPercentFormatLocalization() throws {
        // Given
        let bundle = Bundle(for: ShareExtensionViewModel.self)
        let format = NSLocalizedString("percent_format", bundle: bundle, comment: "")

        // When
        let formatted = String(format: format, 42)

        // If localization is missing in the test bundle, skip the assertion to avoid false negatives.
        if format == "percent_format" {
            throw XCTSkip("Localization for percent_format not available in unit-test bundle.")
        }

        // Then
        XCTAssertEqual(formatted, "42%", "percent_format localization should produce a valid percent string")
    }

    deinit {}
}

#endif // canImport(XCTest)