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

    /// Добавлять операции можно только из пустых ячеек — отдельной кнопки внизу
    /// больше нет, поэтому ячейки зовут добавить в любом режиме
    func testEmptyCellsOfferAddingOutsideEditMode() {
        let app = launchAndSkipOnboarding()

        XCTAssertTrue(app.buttons["operation_row_translate"].firstMatch.waitForExistence(timeout: 5))
        // Дефолтный набор занимает не больше семи ячеек (сколько именно — зависит от
        // языка системы), значит восьмая пуста и предлагает добавить
        let addCell = app.buttons["operation_add_slot_7"].firstMatch
        XCTAssertTrue(addCell.waitForExistence(timeout: 3), "Пустая ячейка должна звать добавить и вне режима правки")

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

    /// Перетаскивание в уже включённом режиме правки — опора для теста ниже:
    /// пока этот проходит, провал соседнего означает сорванное удержание,
    /// а не сломанный перенос вообще
    func testDragSwapsTilesInEditMode() {
        let app = launchAndSkipOnboarding()
        XCTAssertTrue(app.buttons["operation_row_explain"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["Edit"].firstMatch.tap()
        XCTAssertTrue(
            app.buttons["operation_delete_explain"].firstMatch.waitForExistence(timeout: 3),
            "Режим правки не включился"
        )

        assertTileSwapsWithNeighbour(in: app)
    }

    /// Одно удержание должно и включить режим правки, и сразу утащить плитку.
    /// Раньше перенос появлялся у плитки только вместе с режимом — то есть уже
    /// под держащим пальцем, — и система его не подхватывала: удержание
    /// срывалось, а тащить приходилось со второго раза
    func testLongPressDragMovesTileWithoutSecondPress() {
        let app = launchAndSkipOnboarding()
        XCTAssertTrue(app.buttons["operation_row_explain"].firstMatch.waitForExistence(timeout: 5))

        assertTileSwapsWithNeighbour(in: app)

        XCTAssertTrue(
            app.buttons["operation_delete_explain"].firstMatch.exists,
            "Удержание не включило режим правки"
        )
    }

    /// Перенос на пустую ячейку — вторая половина приёма плиток: занятая ячейка
    /// меняется местами, пустая просто забирает плитку себе
    func testDragToEmptyCellMovesTile() {
        let app = launchAndSkipOnboarding()
        let source = app.buttons["operation_row_explain"].firstMatch
        XCTAssertTrue(source.waitForExistence(timeout: 5), "Operation tile not found")
        app.buttons["Edit"].firstMatch.tap()

        // Дефолтный набор занимает не больше семи ячеек, значит восьмая пуста
        let emptyCell = app.buttons["operation_add_slot_7"].firstMatch
        XCTAssertTrue(emptyCell.waitForExistence(timeout: 3), "Режим правки не показал пустую ячейку")
        let sourceFrame = source.frame
        let emptyFrame = emptyCell.frame

        let origin = app.coordinate(withNormalizedOffset: .zero)
        origin.withOffset(CGVector(dx: sourceFrame.midX, dy: sourceFrame.midY))
            .press(
                forDuration: 1.0,
                thenDragTo: origin.withOffset(CGVector(dx: emptyFrame.midX, dy: emptyFrame.midY)),
                withVelocity: .slow,
                thenHoldForDuration: 1.0
            )

        // Допуск покрывает наклон дрожания и вынесенный за угол минус
        XCTAssertEqual(
            source.frame.midX,
            emptyFrame.midX,
            accuracy: 12,
            "Плитка должна была переехать в пустую ячейку по горизонтали: "
                + "было x=\(sourceFrame.midX), стало x=\(source.frame.midX), ждали x=\(emptyFrame.midX)"
        )
        XCTAssertEqual(
            source.frame.midY,
            emptyFrame.midY,
            accuracy: 12,
            "Плитка должна была переехать в пустую ячейку по вертикали: "
                + "было y=\(sourceFrame.midY), стало y=\(source.frame.midY), ждали y=\(emptyFrame.midY)"
        )
    }

    /// Тащит плитку «explain» на соседа по ряду и проверяет, что они поменялись
    /// местами. Плитку адресуем идентификатором: в режиме правки все плитки
    /// получают одну подпись «переставить», а порядок в дереве меняется
    /// переносом — элемент, взятый по номеру, указывал бы потом на чужую плитку
    private func assertTileSwapsWithNeighbour(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let source = app.buttons["operation_row_explain"].firstMatch
        // Сосед по ряду: обмен местами меняет только горизонтальную координату,
        // а вертикальная сдвигается ещё и от пустого ряда, который добавляет правка
        let sourceFrame = source.frame
        let tiles = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'operation_row_'"))
        // Допуски крупные: в режиме правки плитки качаются каждая в своей фазе,
        // и координаты соседей по ряду совпадают лишь примерно. Ряды при этом
        // отстоят друг от друга на высоту плитки, а колонки — на её ширину
        let neighbourFrame = (0 ..< tiles.count)
            .map { tiles.element(boundBy: $0).frame }
            .first { abs($0.minY - sourceFrame.minY) < 20 && abs($0.minX - sourceFrame.minX) > 20 }
        guard let neighbourFrame else {
            XCTFail("Не нашёлся сосед по ряду для переноса", file: file, line: line)
            return
        }

        let origin = app.coordinate(withNormalizedOffset: .zero)
        origin.withOffset(CGVector(dx: sourceFrame.midX, dy: sourceFrame.midY))
            .press(
                forDuration: 1.0,
                thenDragTo: origin.withOffset(CGVector(dx: neighbourFrame.midX, dy: neighbourFrame.midY)),
                withVelocity: .slow,
                thenHoldForDuration: 1.0
            )

        // Допуск в несколько точек: в режиме правки рамка плитки прирастает
        // вынесенным за угол минусом и наклоном дрожания, поэтому измеренная
        // до включения правки координата соседа совпадает не до точки
        XCTAssertEqual(
            source.frame.minX,
            neighbourFrame.minX,
            accuracy: 8,
            "Плитка должна была переехать на место соседа: "
                + "было x=\(sourceFrame.minX), стало x=\(source.frame.minX), ждали x=\(neighbourFrame.minX)",
            file: file,
            line: line
        )
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
