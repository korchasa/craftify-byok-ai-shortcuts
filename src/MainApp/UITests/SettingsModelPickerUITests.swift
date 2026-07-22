import XCTest

/// Регрессия iPad-бага: тап по строке «Model» (а затем по поиску в пикере)
/// закрывал весь шит настроек вместо показа списка моделей.
/// Пикер теперь пушится внутри NavigationStack настроек: после возврата
/// «Назад» настройки обязаны остаться на экране.
final class SettingsModelPickerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Общий путь до открытого пикера моделей: онбординг (если есть) → настройки → строка Model
    private func openModelPicker(_ app: XCUIApplication) -> XCUIElement {
        let consentButton = app.buttons["howtouse_skip_button"]
        if consentButton.waitForExistence(timeout: 3) {
            consentButton.tap()
        }

        let settingsButton = app.buttons["home_settings_button"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button not found:\n\(app.debugDescription)")
        settingsButton.tap()

        let modelRow = app.buttons["settings_model_button"]
        XCTAssertTrue(modelRow.waitForExistence(timeout: 5), "Model row not found:\n\(app.debugDescription)")
        modelRow.tap()

        let searchField = app.textFields["model_search_field"]
        XCTAssertTrue(
            searchField.waitForExistence(timeout: 5),
            "Model picker did not appear after tapping the Model row:\n\(app.debugDescription)"
        )
        return searchField
    }

    /// Возврат из пикера кнопкой «Назад»: настройки должны остаться на экране
    private func assertBackReturnsToSettings(_ app: XCUIApplication) {
        let pickerBar = app.navigationBars["Model"]
        XCTAssertTrue(pickerBar.waitForExistence(timeout: 3), "Model nav bar not found:\n\(app.debugDescription)")
        pickerBar.buttons.firstMatch.tap()
        XCTAssertTrue(
            app.buttons["settings_save_button"].waitForExistence(timeout: 5),
            "Settings sheet is gone after leaving the model picker:\n\(app.debugDescription)"
        )
    }

    func testModelRowOpensPickerAndSearchKeepsIt() {
        let app = XCUIApplication()
        app.launch()

        let searchField = openModelPicker(app)

        // Активация поиска и ввод текста не должны сбрасывать пикер
        // (полевой iPad-баг: тап по поиску закрывал попап и шит настроек)
        searchField.tap()
        searchField.typeText("gpt")
        sleep(2)
        XCTAssertTrue(
            searchField.exists,
            "Model picker dismissed after activating search:\n\(app.debugDescription)"
        )

        assertBackReturnsToSettings(app)
    }

    /// Сценарий из полевого бага: ключ в процессе ввода (SecureField в фокусе,
    /// клавиатура открыта), затем открытие пикера моделей.
    func testModelRowWhileEditingKeyKeepsSettingsPresented() {
        let app = XCUIApplication()
        app.launch()

        let consentButton = app.buttons["howtouse_skip_button"]
        if consentButton.waitForExistence(timeout: 3) {
            consentButton.tap()
        }

        let settingsButton = app.buttons["home_settings_button"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        // Ключ уже сохранён на тестовом устройстве — начинаем «Изменить»;
        // на чистом контейнере поле ввода открыто сразу.
        let changeButton = app.buttons["settings_change_key_button"]
        let secureField = app.secureTextFields.firstMatch
        XCTAssertTrue(
            changeButton.waitForExistence(timeout: 3) || secureField.waitForExistence(timeout: 3),
            "Neither masked key row nor edit field found:\n\(app.debugDescription)"
        )
        if changeButton.exists {
            changeButton.tap()
        }
        XCTAssertTrue(secureField.waitForExistence(timeout: 3))
        secureField.tap()
        secureField.typeText("sk-test-1234567890")

        let modelRow = app.buttons["settings_model_button"]
        XCTAssertTrue(modelRow.waitForExistence(timeout: 5))
        modelRow.tap()

        let searchField = app.textFields["model_search_field"]
        XCTAssertTrue(
            searchField.waitForExistence(timeout: 5),
            "Model picker did not appear (editing-key state):\n\(app.debugDescription)"
        )

        assertBackReturnsToSettings(app)
    }

    /// Полевое состояние: провайдер переключён на OpenRouter, затем пикер и поиск.
    func testModelRowAfterSwitchingProviderKeepsSettingsPresented() {
        let app = XCUIApplication()
        app.launch()

        let consentButton = app.buttons["howtouse_skip_button"]
        if consentButton.waitForExistence(timeout: 3) {
            consentButton.tap()
        }

        let settingsButton = app.buttons["home_settings_button"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        let providerPicker = app.otherElements["settings_provider_picker"].firstMatch
        let providerButton = providerPicker.exists ? providerPicker : app.buttons["settings_provider_picker"].firstMatch
        XCTAssertTrue(providerButton.waitForExistence(timeout: 5), "Provider picker not found:\n\(app.debugDescription)")
        providerButton.tap()

        let openRouterItem = app.buttons["OpenRouter"].firstMatch
        XCTAssertTrue(openRouterItem.waitForExistence(timeout: 3), "OpenRouter menu item not found:\n\(app.debugDescription)")
        openRouterItem.tap()

        let modelRow = app.buttons["settings_model_button"]
        XCTAssertTrue(modelRow.waitForExistence(timeout: 5))
        modelRow.tap()

        let searchField = app.textFields["model_search_field"]
        XCTAssertTrue(
            searchField.waitForExistence(timeout: 5),
            "Model picker did not appear (after provider switch):\n\(app.debugDescription)"
        )
        searchField.tap()
        searchField.typeText("claude")
        sleep(2)
        XCTAssertTrue(
            searchField.exists,
            "Model picker dismissed after activating search (after provider switch):\n\(app.debugDescription)"
        )

        assertBackReturnsToSettings(app)
    }

    /// Полевой запуск шёл с переопределением языка через аргументы — проверяем и его.
    func testModelRowWithLanguageOverrideArguments() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        _ = openModelPicker(app)
        assertBackReturnsToSettings(app)
    }
}
