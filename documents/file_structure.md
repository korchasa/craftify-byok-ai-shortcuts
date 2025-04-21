# Структура файлов Craftify

## Основные директории и файлы

- `documents/` — документация проекта
  - `project.md` — обзор, цели, аудитория
  - `architecture.md` — архитектура и паттерны
  - `implementation.md` — команды, стек, окружение
  - `file_structure.md` — структура файлов
  - `developer-manual.md` — руководство разработчика
  - `user-manual.md` — руководство пользователя
  - `whiteboard.md` — временные заметки и прогресс
- `roadmap.md` — поэтапный план реализации
- `.github/workflows/ci.yml` — CI/CD pipeline
- `project.yml` — описание проекта для XcodeGen
- `.xcconfig` — конфигурация сборки
- `Sources/` — исходный код приложения и расширения
- `Tests/` — модульные и UI тесты
- `Resources/` — локализация, ассеты

## Паттерны организации
- Разделение main app и Share Extension по таргетам
- Общий код в CraftifyShared (SwiftPM)
- Документация и спецификации в `documents/`
- Все настройки и CI/CD — через конфигурационные файлы, без ручных изменений в Xcode GUI