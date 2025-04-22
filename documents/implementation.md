# Реализация и стек технологий

## Команды CLI

| Команда         | Описание                                              |
|----------------|-------------------------------------------------------|
| ./run build    | Сборка проекта (xcodegen, xcodebuild)                 |
| ./run test     | Запуск тестов                                         |
| ./run lint     | Проверка стиля (swiftlint)                            |
| ./run format   | Форматирование кода (swiftformat)                     |
| ./run dev      | Сборка и запуск в симуляторе iPhone 14 (iOS 16)       |
| ./run check    | Линт, форматирование, сборка, тесты, проверка размера Share Extension |
| ./run clean    | Очистка артефактов сборки                             |
| ./run logs     | Просмотр логов                                        |

## Технологический стек
- Swift 5.7+
- SwiftUI
- XcodeGen
- SwiftPM (CraftifyShared, LogManagerShared)
- Sentry (только MainApp)
- NDJSON-файл (FIFO, маскирование, atomic write, экспорт, DispatchQueue) для логов
- SwiftGen (локализация)
- GitHub Actions (CI/CD)

## Настройка окружения
1. Клонировать репозиторий.
2. Установить зависимости: Mint, SwiftGen, SwiftLint, SwiftFormat.
3. Сгенерировать проект: `xcodegen`.
4. Собрать и запустить: `./run dev`.
5. Для тестов: `./run test`.
6. Для проверки: `./run check`.

## CLI-инструменты и Mint

| Инструмент     | Версия   | Назначение                        |
| -------------- | -------- | --------------------------------- |
| XcodeGen       | 2.42.0   | Генерация Xcode-проекта           |
| SwiftLint      | 0.59.1   | Анализатор стиля Swift            |
| SwiftFormat    | 0.55.5   | Форматирование кода Swift         |
| xcbeautify     | 2.28.0   | Красивый вывод xcodebuild         |

Mint используется для управления версиями CLI-инструментов. Все зависимости перечислены в `Mintfile` в корне проекта.

После завершения этапа 2 все placeholder-файлы и placeholder-тесты удалены. Проект полностью соответствует требованиям линтера и готов к реализации CraftifyShared.

## DevOps и CI/CD

- Используется GitHub Actions (`.github/workflows/ci.yml`).
- Для ускорения сборки реализовано кэширование:
  - Mint-пакетов (`.mint`)
  - DerivedData (`~/Library/Developer/Xcode/DerivedData`)
  - SwiftPM зависимостей (`.build`, `.swiftpm`)
- Ключи кэша строятся на основе ОС и контрольных файлов (`Mintfile`, `Package.resolved`).
- Кэширование SwiftPM позволяет избежать повторной загрузки и сборки зависимостей, ускоряя pipeline.
- Remove corrupted Package.resolved | rm -f **/Package.resolved | Удаляет все файлы Package.resolved до кэширования SPM и сборки, предотвращая ошибки из-за повреждённого файла

## Различия между локальной и CI/CD сборкой

- **Локально** для всех операций используются Mint и обёрточные скрипты `./run` (например, `./run check`, `./run lint`, `./run build`). Это обеспечивает единообразие версий инструментов и удобство запуска.
- **В CI/CD (GitHub Actions)** для ускорения пайплайна все утилиты (swiftlint, swiftformat, xcodegen, xcodebuild и др.) устанавливаются и вызываются напрямую, без Mint и без использования `./run`-скриптов. Это позволяет избежать накладных расходов на запуск Mint и ускоряет выполнение шагов.

**Пример локального запуска:**
```
./run check
```

**Пример в CI/CD:**
```
swiftlint
swiftformat . --lint --swiftversion 5.7
xcodegen
xcodebuild -project Craftify.xcodeproj -scheme Craftify -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.4' build | xcbeautify
xcodebuild -project Craftify.xcodeproj -scheme Craftify -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 14,OS=16.4' test | xcbeautify
```

Это различие позволяет ускорить CI/CD без потери воспроизводимости и контроля версий инструментов в локальной разработке.