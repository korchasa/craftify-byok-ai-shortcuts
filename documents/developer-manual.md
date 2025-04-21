# Руководство разработчика Craftify

## Установка зависимостей
1. Установить Mint (https://github.com/yonaskolb/Mint)
2. Установить SwiftGen, SwiftLint, SwiftFormat через Mint:
   - `mint install SwiftGen/SwiftGen`
   - `mint install realm/SwiftLint`
   - `mint install nicklockwood/SwiftFormat`
3. Установить XcodeGen: `mint install yonaskolb/XcodeGen`

## Сборка проекта
- Сгенерировать проект: `xcodegen`
- Собрать: `./run build`

## Запуск тестов
- Unit и UI тесты: `./run test`
- Проверка покрытия: отчёт формируется автоматически в CI

## Линтинг и форматирование
- Проверка стиля: `./run lint`
- Форматирование: `./run format`

## CI/CD
- Все проверки и сборки автоматизированы через GitHub Actions (`.github/workflows/ci.yml`)
- Проверка размера Share Extension и покрытие тестами ≥ 80% — обязательны для успешной сборки

## Деплой
- Release-сборка и публикация через Fastlane (см. инструкции в репозитории)
- Подписание и provisioning автоматизированы через Fastlane `match`