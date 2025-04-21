# Реализация и стек технологий

## Команды CLI

| Команда         | Описание                                              |
|----------------|-------------------------------------------------------|
| ./run build    | Сборка проекта (xcodegen, xcodebuild)                 |
| ./run test     | Запуск тестов                                         |
| ./run lint     | Проверка стиля (swiftlint)                            |
| ./run format   | Форматирование кода (swiftformat)                     |
| ./run dev      | Сборка и запуск в симуляторе iPhone 14 (iOS 16)       |
| ./run check    | Линт + сборка + тесты                                 |
| ./run clean    | Очистка артефактов сборки                             |
| ./run logs     | Просмотр логов                                        |

## Технологический стек
- Swift 5.7+
- SwiftUI
- XcodeGen
- SwiftPM (CraftifyShared, LogManagerShared)
- Sentry (только MainApp)
- SQLite/CoreData (логи)
- SwiftGen (локализация)
- GitHub Actions (CI/CD)

## Настройка окружения
1. Клонировать репозиторий.
2. Установить зависимости: Mint, SwiftGen, SwiftLint, SwiftFormat.
3. Сгенерировать проект: `xcodegen`.
4. Собрать и запустить: `./run dev`.
5. Для тестов: `./run test`.
6. Для проверки: `./run check`.