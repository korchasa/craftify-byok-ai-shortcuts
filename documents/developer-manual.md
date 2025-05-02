# Craftify Developer Manual

## Installing Dependencies
1. Установите все необходимые CLI-инструменты одной командой:
   ```sh
   ./run init
   ```
   Это установит через Homebrew: xcodegen, swiftlint, swiftformat, xcbeautify, swiftgen.

## Building the Project
- Сгенерировать проект: `xcodegen`
- Сборка: `./run build`

## Running Tests
- Unit и UI тесты: `./run test`
- Проверка покрытия: автоматически в CI
- Все ключевые сценарии покрыты e2e-тестами, включая Explain (display) и clipboard-операции.

### Важно: запуск тестов для iOS
Для ручного запуска тестов используйте команду с явным симулятором:
```sh
xcodebuild -scheme Common -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.4' test
```
Это позволяет избежать ошибки "CommonTests does not support My Mac's platform: com.apple.platform.macosx".

## Linting and Formatting
- Проверка стиля: `./run lint`
- Форматирование: `./run format`

## CI/CD
- Все проверки и сборки автоматизированы через GitHub Actions (`.github/workflows/ci.yml`).
- Проверка размера ShareExtension и покрытия тестами ≥ 80% обязательна для успешной сборки.

## Deployment
- Release-сборка и публикация через Fastlane (см. инструкции в репозитории).
- Подпись и provisioning автоматизированы через Fastlane `match`.

## Testing and CI Results
- Все тесты (unit, UI, E2E) для Share Extension проходят успешно.
- Инструкции по запуску и тестированию актуальны.
- Покрытие тестами и размер Share Extension автоматически контролируются в CI.

## Processing Timeout Testing
- Таймаут обработки реализован только в ShareExtensionViewModel (по умолчанию 30 секунд).
- Для unit-тестов таймаут ViewModel можно переопределить через processingTimeoutSeconds.
- В E2E-тестах ShareExtensionManager проверяет только ошибки и успехи обработки, но не таймаут.

- Не редактируйте Info.plist и entitlements вручную. Все изменения — только через project.yml, который обрабатывается XcodeGen.

## Retrieving Logs

Для просмотра логов приложения и расширения используйте Unified Log (os_log, subsystem: Internal, только message + metadata):

```sh
./run logs
```

Команда выводит логи из Unified Log (os_log) за последние 24 часа, фильтруя по subsystem Internal, MainApp и ShareExtension, все уровни. Экспорт логов не поддерживается.

Для изменения периода используйте опции log show, например:
```sh
log show --predicate 'subsystem == "Internal"' --style syslog --last 2h
```

## Operation Color & ResultMode: Developer Notes
- InventoryOperation расширена свойством colorHex (hex-код цвета).
- Для всех операций теперь поддерживается признак обработки результата (resultMode):
  - `.clipboard` — результат копируется в буфер обмена (по умолчанию для всех операций).
  - `.display` — результат отображается во всплывающем окне (используется для Explain).
- Для тестов: InventoryManagerStub поддерживает colorHex и resultMode.
- Покрытие: unit-тесты (InventoryOperation, InventoryManager, режимы обработки результата), UI-тесты (Add/EditOperationView, ShareExtensionView), e2e-тесты (ShareExtensionView, Explain).
- Для проверки UI: используйте ShareExtensionViewUITests.swift.

- Операция correct всегда сохраняет стиль максимально, параметр stylePreservationLevel удалён из моделей, UI и тестов.

**Подробные пользовательские инструкции см. в user-manual.md.**

## ShareExtension: UI

- Основной UI реализован в `src/ShareExtension/Sources/ShareExtensionView.swift`
- Кнопка закрытия закреплена через `.safeAreaInset`, всегда доступна
- Весь остальной контент находится в ScrollView
- Все изменения покрыты unit- и e2e-тестами
- Линтер и форматтер проходят без ошибок