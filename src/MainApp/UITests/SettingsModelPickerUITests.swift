import XCTest

/// Регрессия iPad-бага: тап по строке «Model» в настройках закрывал весь шит
/// настроек вместо показа списка моделей.
final class SettingsModelPickerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testModelRowOpensPickerWithoutDismissingSettings() {
        let app = XCUIApplication()
        app.launch()

        // Первый запуск на чистом контейнере показывает онбординг — проходим его.
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

        // Пикер должен появиться (его поле поиска — самый стабильный признак),
        // а кнопка сохранения настроек — остаться в иерархии (шит не закрылся).
        let searchField = app.searchFields.firstMatch
        let pickerAppeared = searchField.waitForExistence(timeout: 5)
        let settingsStillPresented = app.buttons["settings_save_button"].exists
        XCTAssertTrue(
            pickerAppeared,
            "Model picker did not appear after tapping the Model row:\n\(app.debugDescription)"
        )
        XCTAssertTrue(
            settingsStillPresented,
            "Settings sheet dismissed after tapping the Model row:\n\(app.debugDescription)"
        )
    }

    /// Сценарий из полевого бага: ключ в процессе ввода (SecureField в фокусе,
    /// клавиатура открыта), тап по строке «Model» закрывал шит настроек.
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

        let searchField = app.searchFields.firstMatch
        let pickerAppeared = searchField.waitForExistence(timeout: 5)
        let settingsStillPresented = app.buttons["settings_save_button"].exists
        XCTAssertTrue(
            pickerAppeared,
            "Model picker did not appear (editing-key state):\n\(app.debugDescription)"
        )
        XCTAssertTrue(
            settingsStillPresented,
            "Settings sheet dismissed after tapping the Model row while editing the key:\n\(app.debugDescription)"
        )
    }

    /// Полевое состояние: провайдер переключён на OpenRouter, затем тап по «Model».
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

        let searchField = app.searchFields.firstMatch
        let pickerAppeared = searchField.waitForExistence(timeout: 5)
        let settingsStillPresented = app.buttons["settings_save_button"].exists
        XCTAssertTrue(
            pickerAppeared,
            "Model picker did not appear (after provider switch):\n\(app.debugDescription)"
        )
        XCTAssertTrue(
            settingsStillPresented,
            "Settings sheet dismissed after tapping the Model row after switching provider:\n\(app.debugDescription)"
        )
    }

    /// Полевой запуск шёл с переопределением языка через аргументы — проверяем и его.
    func testModelRowWithLanguageOverrideArguments() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let consentButton = app.buttons["howtouse_skip_button"]
        if consentButton.waitForExistence(timeout: 3) {
            consentButton.tap()
        }

        let settingsButton = app.buttons["home_settings_button"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()

        let modelRow = app.buttons["settings_model_button"]
        XCTAssertTrue(modelRow.waitForExistence(timeout: 5))
        modelRow.tap()

        let searchField = app.searchFields.firstMatch
        let pickerAppeared = searchField.waitForExistence(timeout: 5)
        let settingsStillPresented = app.buttons["settings_save_button"].exists
        XCTAssertTrue(pickerAppeared, "Model picker did not appear (language-args launch):\n\(app.debugDescription)")
        XCTAssertTrue(settingsStillPresented, "Settings dismissed (language-args launch):\n\(app.debugDescription)")
    }
}
