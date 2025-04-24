# Реализация и стек технологий

## Команды CLI

| Команда         | Описание                                              |
|----------------|-------------------------------------------------------|
| ./run test     | Запуск тестов                                         |
| ./run dev      | Сборка и запуск в симуляторе iPhone 14 (iOS 16)       |
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

- **Локально** для всех операций используются Mint и обёрточные скрипты `./run` (например, `./run test`, `./run dev`). Это обеспечивает единообразие версий инструментов и удобство запуска.
- **В CI/CD (GitHub Actions)** для ускорения пайплайна все утилиты (swiftlint, swiftformat, xcodegen, xcodebuild и др.) устанавливаются и вызываются напрямую, без Mint и без использования `./run`-скриптов. Это позволяет избежать накладных расходов на запуск Mint и ускоряет выполнение шагов.

**Пример локального запуска:**
```
./run test
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

## API: AuthManager

**Назначение:**
- Безопасное хранение и получение OpenAI API-ключа через Keychain с поддержкой Keychain Sharing (App Group).
- Маскирование ключа для логирования.
- Используется во всех модулях через протокол `AuthManaging` (DI-friendly, поддержка stub для тестов).

**Публичные методы:**
| Метод | Описание |
|-------|----------|
| `getAPIKey() async throws -> String?` | Получить API-ключ (или nil, если не найден) |
| `setAPIKey(_ key: String) async throws` | Сохранить API-ключ (валидируется длина) |
| `deleteAPIKey() async throws` | Удалить API-ключ |
| `maskedAPIKey(_ key: String?) -> String` | Маскирует ключ для логирования (пример: sk-****abcd) |

**Особенности:**
- Все методы async/await (готово к интеграции с современным Swift-кодом).
- Ошибки доступа к Keychain обрабатываются и пробрасываются (accessDenied, invalidKey, itemNotFound).
- Маскирование ключа: только первые 3 и последние 4 символа, остальное заменяется на ****.
- Для тестов реализован in-memory stub (AuthManagerStub), поддерживающий те же методы.

**Пример использования:**
```swift
let authManager: AuthManaging = AuthManager()
try await authManager.setAPIKey("sk-...yourkey...")
let key = try await authManager.getAPIKey()
let masked = authManager.maskedAPIKey(key)
```

## API: LogManagerShared

**Назначение:**
- Централизованное логирование для приложения и расширения.
- FIFO-хранилище логов в формате NDJSON (App Group контейнер), поддержка in-memory stub для тестов.
- Маскирование ключей, экспорт логов, atomic write.

**Публичные методы:**
| Метод | Описание |
|-------|----------|
| `log(_ entry: LogEntry)` | Записать лог (FIFO, NDJSON, atomic write) |
| `getLogs() -> [LogEntry]` | Получить все логи (FIFO) |
| `clearLogs()` | Очистить все логи |
| `exportLogs() throws -> Data` | Экспортировать логи в JSON |

**Особенности:**
- NDJSON-файл в App Group (максимум 1000 записей, автоматическое удаление старых).
- Маскирование ключей аналогично AuthManager.
- Для тестов — in-memory реализация (LogManagerSharedInMemory).
- Все операции потокобезопасны (DispatchQueue).

**Пример использования:**
```swift
let logger: LogManagerShared = LogManagerSharedNDJSON(appGroupContainerURL: ...)
logger.log(LogEntry(level: .info, module: "ShareExt", message: "Started", metadata: [:]))
let logs = logger.getLogs()
let exported = try logger.exportLogs()
```

## LogManagerShared: реализация

- **NDJSON-реализация (LogManagerSharedNDJSON):**
  - Хранит логи в NDJSON-файле в App Group контейнере.
  - FIFO: при превышении 1000 записей автоматически удаляет старые.
  - Все операции потокобезопасны (DispatchQueue).
  - Маскирование ключей, экспорт логов, atomic write.
  - Файл: `src/CraftifyShared/Sources/LogManagerSharedNDJSON.swift`

- **In-memory реализация (LogManagerSharedInMemory):**
  - Используется для unit-тестов.
  - FIFO, маскирование, экспорт аналогично production.
  - Файл: `src/CraftifyShared/Sources/LogManagerSharedInMemory.swift`

- **Протокол LogManagerShared:**
  - Описывает общий API для логирования, FIFO, экспорта, маскирования.
  - Файл: `src/CraftifyShared/Sources/LogManagerShared.swift`

- **Структура лога:**
  - LogEntry: уровень, модуль, сообщение, метаданные, timestamp.
  - Файл: `src/CraftifyShared/Sources/LogEntry.swift`

## Тестирование AuthManager

| Тест | Тип | Описание |
|-------|-----|----------|
| `testSetAndGetAPIKey` | Unit | Проверка установки и получения API-ключа через AuthManagerStub |
| `testDeleteAPIKey` | Unit | Проверка удаления API-ключа через AuthManagerStub |
| `testSetShortAPIKeyThrows` | Unit | Проверка ошибки при установке короткого ключа |
| `testMaskedAPIKey` | Unit | Проверка маскирования ключа |
| `testMaskedAPIKeyShortOrNil` | Unit | Проверка маскирования nil/короткого ключа |
| `testGetAPIKey_accessDenied_throws` | Unit | Проверка ошибки доступа (accessDenied) через AuthManagerStub |
| `testGetAPIKey_itemNotFound_throws` | Unit | Проверка ошибки отсутствия элемента (itemNotFound) через AuthManagerStub |

## Тестирование Masking (maskKey)

| Тест | Тип | Описание |
|------|-----|----------|
| `testMaskKey_NormalKey` | Unit | Маскирование обычного ключа (длиннее min длины, видны только последние 4 символа) |
| `testMaskKey_ExactlyMinLength` | Unit | Маскирование ключа ровно минимальной длины (всё скрыто) |
| `testMaskKey_ShortKey` | Unit | Маскирование короткого ключа (всё скрыто) |
| `testMaskKey_NilKey` | Unit | Маскирование nil (всё скрыто) |

## Запуск тестов
- Unit и UI тесты: `./run test`
- Проверка покрытия: отчёт формируется автоматически в CI
- Обязательное требование: все ключевые пользовательские сценарии должны быть покрыты end-to-end тестами (E2E), включая edge-cases и негативные сценарии.

## Итоги ревью и тестирования Share Extension
- Все требования MVP для Share Extension выполнены.
- Размер расширения ≤20 MB подтверждён ручной сборкой и анализом зависимостей.
- Покрытие тестами (unit, UI, E2E) ≥80%.
- Все edge-cases реализованы и протестированы.
- Линтинг (SwiftLint) и форматирование (SwiftFormat) — без ошибок.

## Этап 5: Реализация Share Extension (статус: завершён)

- Полностью реализован Share Extension с поддержкой всех требований MVP.
- Настроены entitlements (App Groups, Keychain Access) для обоих таргетов.
- Лимит текста: 5000 символов, блокировка кнопок операций при превышении лимита.
- Обработка таймаутов: 15 с на запрос, 30 с общий лимит (Task.sleep + Task.cancel).
- Отображение тоста/уведомления при успешном копировании результата.
- Интеграция LogManagerSharedNDJSON: логируются все действия и ошибки, маскирование ключа.
- Покрытие unit, UI и E2E тестами (ошибки, таймауты, edge-cases).
- В CI/CD реализована автоматическая проверка размера расширения (Archive + size report, fail при >20 MB).

### Команды и шаги CI/CD для проверки размера Share Extension

| Шаг | Описание |
|-----|----------|
| xcodegen | Генерация Xcode-проекта |
| xcodebuild build -scheme ShareExtension -configuration Release -sdk iphoneos | Сборка расширения в Release |
| du -sk build/Products/Release-iphoneos/ShareExtension.appex | Получение размера .appex |
| Fail при >20 MB | Сборка прерывается, если размер превышает лимит |