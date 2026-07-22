import XCTest

/// Экран операции: итоговый текст промпта редактируется на месте,
/// кнопка сброса возвращает дефолт из шаблона
final class EditOperationPromptUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPromptEditorVisibleAndResetRestoresDefault() {
        let app = XCUIApplication()
        app.launch()

        let consentButton = app.buttons["howtouse_skip_button"]
        if consentButton.waitForExistence(timeout: 3) {
            consentButton.tap()
        }

        // Открываем первую операцию из списка
        let firstRow = app.buttons["operation_row_translate"].firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 5), "Operation row not found:\n\(app.debugDescription)")
        firstRow.tap()

        let editor = app.textViews["edit_prompt_editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5), "Prompt editor not found:\n\(app.debugDescription)")

        let resetButton = app.buttons["edit_prompt_reset_button"]
        XCTAssertTrue(resetButton.exists)
        XCTAssertFalse(resetButton.isEnabled, "Reset must be disabled while prompt equals the template default")

        // Правка текста делает промпт пользовательским — сброс становится доступен
        editor.tap()
        editor.typeText("CUSTOM ")
        XCTAssertTrue(resetButton.isEnabled, "Reset must enable after editing the prompt")

        resetButton.tap()
        XCTAssertFalse(resetButton.isEnabled, "Reset must disable after restoring the template default")
    }
}
