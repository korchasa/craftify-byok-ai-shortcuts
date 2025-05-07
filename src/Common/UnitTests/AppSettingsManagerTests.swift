import XCTest

final class AppSettingsManagerTests: XCTestCase {
    func testNativeLanguageSaveAndRead() {
        let suiteName = "group.dev.korchasa.Craftify"
        let manager = AppSettingsManager(suiteName: suiteName)
        let testLang = "ru"
        manager.nativeLanguage = testLang
        let readLang = manager.nativeLanguage
        XCTAssertEqual(readLang, testLang, "AppSettingsManager должен сохранять и читать язык через App Group")
    }
}
