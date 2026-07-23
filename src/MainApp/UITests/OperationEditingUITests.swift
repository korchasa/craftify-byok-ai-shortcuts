import XCTest

/// Экран операции в компактной вёрстке: цвет выбирается через всплывающую
/// палитру по тапу на иконку, а удаление живёт на списке (свайп), а не в форме
final class OperationEditingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    private func launchAndSkipOnboarding() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        let consentButton = app.buttons["howtouse_skip_button"]
        if consentButton.waitForExistence(timeout: 3) {
            consentButton.tap()
        }
        return app
    }

    func testColorPickerPopoverOpensAndSelects() {
        let app = launchAndSkipOnboarding()

        let row = app.buttons["operation_row_translate"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Operation row not found")
        row.tap()

        let colorButton = app.buttons["edit_color_button"]
        XCTAssertTrue(colorButton.waitForExistence(timeout: 5), "Color button not found")

        // Палитра не показана, пока не тапнули по иконке
        let swatches = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'operation_color_swatch_'"))
        XCTAssertEqual(swatches.count, 0, "Swatches must be hidden before opening the picker")

        colorButton.tap()
        let firstSwatch = swatches.element(boundBy: 0)
        XCTAssertTrue(firstSwatch.waitForExistence(timeout: 3), "Popover swatches did not appear")
        XCTAssertGreaterThan(swatches.count, 1, "Expected multiple color swatches")

        // Выбор цвета закрывает палитру
        let secondSwatch = swatches.element(boundBy: 1)
        secondSwatch.tap()
        XCTAssertTrue(firstSwatch.waitForNonExistence(timeout: 3), "Popover must dismiss after picking a color")
    }

    func testSwipeRevealsDeleteOnListRow() {
        let app = launchAndSkipOnboarding()

        // Строка операции — кнопка; проверяем, что она не перехватывает свайп
        // и удаление доступно на списке, а не в форме (тест неразрушающий)
        let row = app.buttons["operation_row_translate"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Operation row not found")

        row.swipeLeft()
        let deleteButton = app.buttons["Delete"].firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "Swipe did not reveal the Delete action on the list row")
    }
}
