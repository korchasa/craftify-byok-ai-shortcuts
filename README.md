# Craftify

Craftify — iOS-приложение с расширением Share Extension для контекстной обработки текста через OpenAI API.

## Установка и запуск

1. Клонируйте репозиторий:
   ```sh
   git clone <repo-url>
   cd Craftify-Cursor
   ```
2. Установите все необходимые CLI-инструменты:
   ```sh
   ./run init
   ```
   Это установит через Homebrew: xcodegen, swiftlint, swiftformat, xcbeautify, swiftgen.
3. Сгенерируйте проект:
   ```sh
   ./run generate
   ```
4. Соберите и запустите проект:
   ```sh
   ./run deploy:simulator
   ```
5. Для запуска проверок:
   ```sh
   ./run check
   ```

## Основные команды
- `./run init` — установка всех CLI-инструментов
- `./run deploy:simulator` — сборка и запуск в симуляторе
- `./run check` — запуск всех проверок
- `./run clean` — очистка артефактов сборки
- `./run logs` — просмотр логов

## CI/CD
- Все проверки и сборки автоматизированы через GitHub Actions (`.github/workflows/ci.yml`)
- Проверка размера Share Extension и покрытие тестами ≥ 80% — обязательны для успешной сборки

## Архитектура
- Модули: MainApp, ShareExtension, Common (SPM)
- App Group: `group.dev.korchasa.Craftify`
- Keychain Sharing: `group.dev.korchasa.Craftify`

## Экспорт логов

- Для диагностики и поддержки пользователь может экспортировать логи приложения через раздел настроек (SettingsView).
- В разделе настроек нажмите кнопку "Экспорт логов" — откроется системное меню экспорта (share sheet) с файлом логов в формате JSON.
- Логи содержат максимум 1000 последних записей (FIFO), все ключи API маскированы (видны только первые и последние 4 символа).
- Логи доступны только внутри контейнера App Group и не передаются третьим лицам.
- Краш-отчёты отправляются только из основного приложения через New Relic SDK (не из расширения).

## Документация
- Подробная документация находится в директории `documents/`

> После завершения этапа 2 все placeholder-файлы и placeholder-тесты удалены. Проект полностью соответствует требованиям линтера и готов к реализации Common.

## Migration to Tuist

The project is now fully managed by Tuist:
- All targets, dependencies, resources, and schemes are described in Project.swift and Workspace.swift.
- XcodeGen, project.yml, .xcodeproj, and .xcworkspace are removed (replaced by Tuist manifests).
- All builds and tests are performed via tuist and CLI scripts (see ./run).
- This ensures reproducible, DevOps-friendly, and CI/CD-compatible workflows.

## DevOps-friendly flow
- All project structure and configuration are described in code (Project.swift, Workspace.swift, configs).
- No manual steps: all builds, tests, and code generation are automated.
- Easy onboarding: just run ./run init and ./run generate.