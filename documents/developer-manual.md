# Руководство разработчика Craftify

## Установка зависимостей
1. Установить все необходимые CLI-инструменты одной командой:
   ```sh
   ./run init
   ```
   Это установит через Homebrew: xcodegen, swiftlint, swiftformat, xcbeautify, swiftgen.

## Сборка проекта
- Сгенерировать проект: `xcodegen`
- Собрать: `./run build`

## Запуск тестов
- Unit и UI тесты: `./run test`
- Проверка покрытия: отчёт формируется автоматически в CI
- Обязательное требование: все ключевые пользовательские сценарии должны быть покрыты end-to-end тестами (E2E), включая edge-cases и негативные сценарии.

### Важно: запуск тестов для iOS
Для запуска тестов вручную используйте команду с явным указанием симулятора:
```
xcodebuild -scheme Common -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.4' test
```
Это исключает ошибку "CommonTests does not support My Mac's platform: com.apple.platform.macosx".

## Линтинг и форматирование
- Проверка стиля: `./run lint`
- Форматирование: `./run format`

## CI/CD
- Все проверки и сборки автоматизированы через GitHub Actions (`.github/workflows/ci.yml`)
- Проверка размера Share Extension и покрытие тестами ≥ 80% — обязательны для успешной сборки

## Деплой
- Release-сборка и публикация через Fastlane (см. инструкции в репозитории)
- Подписание и provisioning автоматизированы через Fastlane `match`

## Итоги тестирования и CI
- Все тесты (unit, UI, E2E) для Share Extension проходят успешно.
- Инструкции по запуску и тестированию актуальны.
- Покрытие тестами и размер Share Extension контролируются автоматически в CI.

## Тестирование таймаута обработки
- Таймаут обработки реализован только в ShareExtensionViewModel (по умолчанию 30 секунд).
- Для unit-тестов ViewModel таймаут можно переопределять через свойство processingTimeoutSeconds.
- В E2E тестах ShareExtensionManager таймаут не тестируется, только ошибки и успехи обработки.