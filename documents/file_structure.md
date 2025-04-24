## Структура файлов проекта Craftify

```
src/
  MainApp/
    Sources/      # Исходники основного приложения
    Resources/    # Ресурсы (иконки, .strings и др.)
    Config/       # Info.plist, entitlements
  ShareExtension/
    Sources/      # Исходники расширения
    Resources/    # Ресурсы расширения
    Config/       # Info.plist, entitlements
    ClipboardManager.swift
    ClipboardManaging.swift
    ProcessingManager.swift
    ProcessingManaging.swift
    ShareExtensionViewController.swift
    UnitTests/
      - AuthManagerTests.swift
      - ConsentManagerTests.swift
      - InventoryManagerTests.swift
      - LogManagerSharedInMemoryTests.swift
      - LogManagerSharedNDJSONTests.swift
      - MaskingTests.swift   # Тесты для maskKey (маскирование ключей)
      - OperationModelsTests.swift
      - XCTestAsyncHelpers.swift
      - ShareExtensionManagerTests.swift
  CraftifyShared/
    Sources/      # Исходники общей библиотеки
    Config/       # Info.plist
    Tests/        # Unit-тесты CraftifyShared
    - UnitTests/
      - AuthManagerTests.swift
      - ConsentManagerTests.swift
      - InventoryManagerTests.swift
      - LogManagerSharedInMemoryTests.swift
      - LogManagerSharedNDJSONTests.swift
      - MaskingTests.swift   # Тесты для maskKey (маскирование ключей)
      - OperationModelsTests.swift
      - XCTestAsyncHelpers.swift
```

Корень репозитория:
- project.yml, run, Dockerfile, README.md
- .github/ — CI/CD
- documents/ — документация

Все пути в project.yml обновлены на src/…

### Основные директории и файлы

- `documents/` — документация проекта
  - `project.md` — обзор, цели, аудитория
  - `architecture.md` — архитектура и паттерны
  - `implementation.md` — команды, стек, окружение
  - `file_structure.md` — структура файлов
  - `developer-manual.md` — руководство разработчика
  - `user-manual.md` — руководство пользователя
- `.github/workflows/ci.yml` — CI/CD pipeline
- `project.yml` — описание проекта для XcodeGen
- `.xcconfig` — конфигурация сборки
- `Sources/` — исходный код приложения и расширения
- `Tests/` — модульные и UI тесты, а также end-to-end (E2E) тесты для всех ключевых пользовательских сценариев
- `Resources/` — локализация, ассеты
- App Group контейнер: logs.ndjson — хранилище логов (FIFO, NDJSON)

### Паттерны организации
- Разделение main app и Share Extension по таргетам
- Общий код в CraftifyShared (SwiftPM)
- Документация и спецификации в `documents/`
- Все настройки и CI/CD — через конфигурационные файлы, без ручных изменений в Xcode GUI

// Удалены placeholder-файлы и placeholder-тесты после завершения этапа 2. Структура актуальна на момент перехода к этапу 3.

| src/ShareExtension/Sources/ClipboardManager.swift | Менеджер работы с UIPasteboard (копирование результата) |
| src/ShareExtension/Sources/ClipboardManaging.swift | Протокол для ClipboardManager (DI, тестируемость) |
| src/ShareExtension/Sources/ProcessingManager.swift | Асинхронная обработка текста, интеграция с LLMAPIClient |
| src/ShareExtension/Sources/ProcessingManaging.swift | Протокол для ProcessingManager (DI, тестируемость) |
| src/ShareExtension/Sources/ShareExtensionViewController.swift | Контроллер расширения, интеграция SwiftUI и UIKit |
| src/ShareExtension/UnitTests/ShareExtensionManagerTests.swift | Unit-тесты для ShareExtensionManager |

- Тесты, связанные с таймаутом обработки, реализованы только в unit-тестах ViewModel (ShareExtensionViewModelTests.swift), а не в E2E тестах ShareExtensionManager.

- `size-report.txt` — артефакт CI: размер ShareExtension.appex (автоматически сохраняется при сборке)
- `metrics.json` — артефакт CI: build_time_sec, appex_size_mb (автоматически сохраняется при сборке)
- `.github/workflows/ci.yml` — содержит шаги size-report, comment-scan, build-time metrics
- В проекте отсутствуют .xcassets, PDF, PNG, SVG и другие image assets (только Placeholder.txt и .strings)