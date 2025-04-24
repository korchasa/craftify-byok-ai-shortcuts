# Архитектура Craftify

## Общая схема
- Основное приложение (SwiftUI) и Share Extension используют общий модуль CraftifyShared (SwiftPM).
- Взаимодействие между модулями через App Group (UserDefaults) и Keychain Sharing.
- Логирование через LogManagerShared (SPM), хранение логов в App Group контейнере (NDJSON-файл, FIFO, маскирование, экспорт, atomic write, DispatchQueue).

## Ключевые паттерны
- MVVM + SwiftUI для UI и бизнес-логики.
- Dependency Injection для менеджеров.
- FIFO для логов (ограничение 1000 записей).

## Взаимодействие компонентов
- ShareExtensionManager читает inventory и API-ключ, вызывает ProcessingManager.
- ProcessingManager формирует запрос, вызывает LLMAPIClient.
- LLMAPIClient отправляет HTTP POST к OpenAI, парсит ответ через ResponseParser.
- ClipboardManager копирует результат в UIPasteboard.
- Все действия логируются через LogManagerShared.

## Обработка ошибок
- Все ошибки (Keychain, сеть, парсинг, буфер обмена) обрабатываются с показом Alert.
- Повторные попытки при сетевых ошибках (экспоненциальный backoff).
- Маскирование API-ключа в логах.
- При ошибках доступа к ключу — предложение открыть Settings.

## Тестирование
- Unit-тесты для всех менеджеров.
- UI/E2E-тесты для основных сценариев (обязательное требование: все ключевые пользовательские сценарии должны быть покрыты end-to-end тестами, включая edge-cases и негативные сценарии).
- Покрытие ≥ 80% для ключевых модулей.

## Итоги реализации Share Extension
- Архитектурные решения (DI, логирование, обработка ошибок, тестируемость) реализованы в полном соответствии с документацией.
- Все компоненты и взаимодействия соответствуют описанию в данной архитектуре.

## Share Extension: финальная архитектура

- Все менеджеры внедряются через DI, включая LogManagerSharedNDJSON (App Group).
- Логирование всех действий и ошибок, маскирование ключа, FIFO, экспорт NDJSON.
- Лимит текста: 5000 символов, блокировка на UI и в менеджере.
- Таймауты: 15 с на запрос, 30 с общий лимит (Task.sleep + Task.cancel).
- Обработка ошибок: все сценарии покрыты (нет текста, лимит, нет согласия, неверный ключ, сеть, парсинг, буфер, отмена).
- Покрытие unit, UI, E2E тестами (≥80%).
- В CI/CD реализована автоматическая проверка размера расширения (Archive + size report, fail при >20 MB).

### Обновлённая диаграмма взаимодействий

```mermaid
graph TD
  ShareExtension[Share Extension] -->|UserDefaults| AppGroup[UserDefaults (App Group)]
  ShareExtension --> ProcessingManager[Processing Manager]
  ProcessingManager --> LLMAPIClient[LLM API Client]
  LLMAPIClient --> UIPasteboard[UIPasteboard]
  subgraph Shared
    LogManagerShared[Log Manager Shared]
  end
  ShareExtension & ProcessingManager & LLMAPIClient & UIPasteboard -.-> LogManagerShared
```