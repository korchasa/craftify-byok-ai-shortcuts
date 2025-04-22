# Структура файлов проекта Craftify

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
  CraftifyShared/
    Sources/      # Исходники общей библиотеки
    Config/       # Info.plist
    Tests/        # Unit-тесты CraftifyShared
```

Корень репозитория:
- Mintfile, project.yml, run, Dockerfile, README.md
- .github/ — CI/CD
- documents/ — документация

Все пути в project.yml обновлены на src/…

## Основные директории и файлы

- `documents/` — документация проекта
  - `project.md` — обзор, цели, аудитория
  - `architecture.md` — архитектура и паттерны
  - `implementation.md` — команды, стек, окружение
  - `file_structure.md` — структура файлов
  - `developer-manual.md` — руководство разработчика
  - `user-manual.md` — руководство пользователя
- `roadmap.md` — поэтапный план реализации
- `.github/workflows/ci.yml` — CI/CD pipeline
- `project.yml` — описание проекта для XcodeGen
- `.xcconfig` — конфигурация сборки
- `Sources/` — исходный код приложения и расширения
- `Tests/` — модульные и UI тесты
- `Resources/` — локализация, ассеты
- App Group контейнер: logs.ndjson — хранилище логов (FIFO, NDJSON)

## Паттерны организации
- Разделение main app и Share Extension по таргетам
- Общий код в CraftifyShared (SwiftPM)
- Документация и спецификации в `documents/`
- Все настройки и CI/CD — через конфигурационные файлы, без ручных изменений в Xcode GUI

// Удалены placeholder-файлы и placeholder-тесты после завершения этапа 2. Структура актуальна на момент перехода к этапу 3.