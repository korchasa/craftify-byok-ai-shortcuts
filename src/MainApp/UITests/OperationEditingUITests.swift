import XCTest

/// Экран операции в компактной вёрстке: цвет выбирается через всплывающую
/// палитру по тапу на иконку, а удаление живёт на плитке — кружок с минусом
/// в режиме правки, как у иконок приложений в iOS
final class OperationEditingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    /// Каждый тест стартует с дефолтным списком операций: удаление в одном тесте
    /// иначе живёт в хранилище App Group и роняет все следующие прогоны.
    /// Язык фиксируем на английском: тест ищет системные кнопки «Edit», «Cancel»
    /// и «Delete» по надписи, а она зависит от языка симулятора
    private func launchAndSkipOnboarding() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-CraftifyResetInventory", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
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

    func testDeleteBadgeAsksConfirmationBeforeRemoving() {
        let app = launchAndSkipOnboarding()

        let tile = app.buttons["operation_row_translate"].firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 5), "Operation tile not found")

        app.buttons["Edit"].firstMatch.tap()

        let badge = app.buttons["operation_delete_translate"].firstMatch
        XCTAssertTrue(badge.waitForExistence(timeout: 3), "Edit mode did not reveal the delete badge on the tile")

        badge.tap()
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 3), "Delete badge must ask for confirmation")

        // Отмена оставляет операцию на месте — тест неразрушающий
        alert.buttons["Cancel"].firstMatch.tap()
        XCTAssertTrue(alert.waitForNonExistence(timeout: 3), "Alert must dismiss on Cancel")
        XCTAssertTrue(tile.exists, "Cancelling the confirmation must keep the operation")
    }

    func testEditModeShowsAddButtonOnEmptyCells() {
        let app = launchAndSkipOnboarding()

        XCTAssertTrue(app.buttons["operation_row_translate"].firstMatch.waitForExistence(timeout: 5))
        // Дефолтный набор занимает не больше семи ячеек (сколько именно — зависит от
        // языка системы), значит восьмая пуста и предлагает добавить
        XCTAssertFalse(app.buttons["operation_add_slot_7"].exists, "Пустые ячейки не должны звать добавлять вне режима правки")

        app.buttons["Edit"].firstMatch.tap()

        let addCell = app.buttons["operation_add_slot_7"].firstMatch
        XCTAssertTrue(addCell.waitForExistence(timeout: 3), "Edit mode did not reveal the add button on the empty cell")

        addCell.tap()
        XCTAssertTrue(
            app.staticTexts["Add Operation"].firstMatch.waitForExistence(timeout: 3),
            "Tapping an empty cell must open the add form"
        )
    }

    /// Долгое нажатие по плитке включает режим правки — как удержание иконки
    /// на домашнем экране iOS, а не только кнопка «Edit» в шапке
    func testLongPressOnTileTurnsOnEditMode() {
        let app = launchAndSkipOnboarding()

        let tile = app.buttons["operation_row_translate"].firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 5), "Operation tile not found")

        let badge = app.buttons["operation_delete_translate"].firstMatch
        XCTAssertFalse(badge.exists, "Вне режима правки минуса на плитке быть не должно")

        tile.press(forDuration: 1.0)

        XCTAssertTrue(badge.waitForExistence(timeout: 3), "Долгое нажатие по плитке не включило режим правки")
        // Отпускание пальца после удержания не должно вдобавок открывать форму правки
        XCTAssertFalse(app.textViews["edit_prompt_editor"].exists, "Удержание не должно открывать форму правки")
    }

    func testEditModeShowsDeleteBadgeAndRemovesTile() {
        let app = launchAndSkipOnboarding()

        let tile = app.buttons["operation_row_explain"].firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 5), "Operation tile not found")

        app.buttons["Edit"].firstMatch.tap()

        let badge = app.buttons["operation_delete_explain"].firstMatch
        XCTAssertTrue(badge.waitForExistence(timeout: 3), "Edit mode did not reveal the delete badge on the tile")

        badge.tap()
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 3), "Delete badge must ask for confirmation")

        alert.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(tile.waitForNonExistence(timeout: 3), "Confirming the deletion must remove the tile")
    }
}
