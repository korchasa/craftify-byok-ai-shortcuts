# Руководство разработчика Craftify

## Установка зависимостей
1. Установить Mint (https://github.com/yonaskolb/Mint)
2. Установить SwiftGen, SwiftLint, SwiftFormat через Mint:
   - `mint install SwiftGen/SwiftGen`
   - `mint install realm/SwiftLint`
   - `mint install nicklockwood/SwiftFormat`
3. Установить XcodeGen: `mint install yonaskolb/XcodeGen`

### Установка CLI-инструментов через Mint

1. Установите Mint (если не установлен):
   ```sh
   brew install mint
   ```
2. Установите все инструменты, необходимые проекту:
   ```sh
   mint bootstrap
   ```
   Mint установит версии CLI-инструментов, указанные в `Mintfile`.

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
xcodebuild -scheme CraftifyShared -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.4' test
```
Это исключает ошибку "CraftifySharedTests does not support My Mac's platform: com.apple.platform.macosx".

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