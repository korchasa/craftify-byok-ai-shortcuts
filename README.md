# Craftify

Craftify — iOS-приложение с расширением Share Extension для контекстной обработки текста через OpenAI API.

## Быстрый старт

```sh
git clone <repo-url>
cd Craftify-Cursor
# Генерация Xcode-проекта
xcodegen
# Сборка и тесты
./run test
```

## Сборка и запуск
- Генерация проекта: `xcodegen`
- Сборка: `./run build`
- Тесты: `./run test`
- Линт: `./run lint`
- Форматирование: `./run format`
- Запуск в симуляторе: `./run dev`

## Docker
Для изолированной сборки и тестирования:
```sh
docker build -t craftify .
docker run -it craftify
```

## CI/CD
- GitHub Actions: `.github/workflows/ci.yml`
- Проверка размера Share Extension (fail > 20MB)
- Линт, форматирование, тесты, SwiftGen на prebuild

## Архитектура
- Модули: MainApp, ShareExtension, CraftifyShared (SPM)
- App Group: `group.dev.korchasa.Craftify`
- Keychain Sharing: `group.dev.korchasa.Craftify`

## Документация
- ADR: `documents/adr/0001-modular-architecture.md`
- Архитектура: `documents/architecture.md`
- Руководства: `documents/`

> После завершения этапа 2 все placeholder-файлы и placeholder-тесты удалены. Проект полностью соответствует требованиям линтера и готов к реализации CraftifyShared.