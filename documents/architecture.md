## Architecture Craftify

### General Scheme
- Основное приложение (SwiftUI) и Share Extension используют общий модуль Common (SwiftPM).
- Взаимодействие между модулями через App Group (UserDefaults) и Keychain Sharing.
- Логирование через LogManagerShared (SPM), хранение логов в os log.
- Для всех операций теперь поддерживается признак обработки результата (resultMode):
  - `.clipboard` — результат копируется в буфер обмена (по умолчанию для всех операций).
  - `.display` — результат отображается во всплывающем окне (используется для Explain).

### Key Patterns
- MVVM + SwiftUI для UI и бизнес-логики.
- Dependency Injection для менеджеров.
- FIFO для логов (лимит 1000 записей).

### Logging and Analytics

#### Log Architecture
- Все логи пишутся через системный лог (Unified Logging, os_log, subsystem: Internal, только message + metadata) через OSLogManagerShared. Экспорт логов не поддерживается, просмотр — через Console.app, log stream или ./run logs.
- LogManagerShared поддерживает уровни: debug, info, warning, error. В production логируются только message + metadata.
- API-ключи всегда маскируются (видны только первые и последние 4 символа).
- Crash reporting реализован через New Relic SDK (только в основном приложении).
- В Share Extension не используются сторонние SDK для аналитики и crash reporting (минимальный размер, соответствие App Store).

#### Log Export and Retention Policy
- Экспорт логов не поддерживается (ограничение system log). Просмотр — только через системные средства.
- Crash reports отправляются только из основного приложения через New Relic SDK.

#### Consequences
- Логи доступны только для диагностики через system tools или ./run logs (фильтрация по subsystem Internal, все уровни, MainApp и ShareExtension).
- Crash analytics — только для основного приложения.
- Share Extension остаётся лёгким и соответствует privacy-требованиям.
- Политика маскировки ключей реализована на уровне кода.

### Component Interaction
- ShareExtensionManager читает inventory и API-ключ, вызывает ProcessingManager.
- ProcessingManager формирует запрос, вызывает LLMAPIClient.
- LLMAPIClient отправляет HTTP POST в OpenAI, парсит ответ через ResponseParser.
- ClipboardManager копирует результат в UIPasteboard.
- Если операция с resultMode `.display` (Explain) — результат сохраняется и отображается во вью, не копируется в буфер.
- Все действия логируются через LogManagerShared.

### Error Handling
- Все ошибки (Keychain, сеть, парсинг, буфер обмена) обрабатываются с показом Alert.
- Повторные попытки при сетевых ошибках (exponential backoff).
- Маскирование API-ключа в логах.
- В случае ошибок доступа к ключу — предложение открыть настройки.

### Testing
- Unit-тесты для всех менеджеров и моделей.
- UI/E2E-тесты для всех основных сценариев, включая Explain (display) и clipboard-операции.
- Проверяется, что Explain отображает результат, а остальные операции копируют в буфер.
- Покрытие ≥ 80% для ключевых модулей.

### Results of Share Extension Implementation
- Архитектурные решения (DI, логирование, обработка ошибок, тестируемость) реализованы в полном соответствии с документацией.
- Все компоненты и взаимодействия соответствуют описанию.
- Поддержка resultMode для операций.

### Share Extension: Final Architecture

- Все менеджеры внедряются через DI, включая OSLogManagerShared.
- Логирование всех действий и ошибок, маскирование ключей.
- Лимит текста: 5000 символов, блокировка на UI и в менеджере.
- Таймауты: 15 секунд на запрос, 30 секунд общий лимит.
- Обработка ошибок: все сценарии покрыты (нет текста, лимит, нет согласия, неверный ключ, сеть, парсинг, буфер, отмена).
- Покрытие unit, UI, E2E тестами (≥80%).
- В CI/CD реализована автоматическая проверка размера расширения (Archive + size report, fail если >20 МБ).

#### Updated Interaction Diagram

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
  ShareExtension -->|resultMode .display| ShareExtensionView[ShareExtensionView: Display Result]
```

### Targets and Schemes

- MainApp
- MainAppUnitTests
- MainAppE2ETests
- ShareExtension
- ShareExtensionUnitTests
- ShareExtensionE2ETests
- CommonUnitTests
- CommonE2ETests
- ShareExtensionSizeReport

**Подробные описания операций и промптов см. в user-manual.md и developer-manual.md.**

## Timeout Mechanism for Text Processing
- Таймаут обработки реализован только на уровне ShareExtensionViewModel (по умолчанию 30 секунд, можно переопределить в тестах).
- ShareExtensionManager не реализует таймаут, только бизнес-логику обработки и ошибок.
- В unit-тестах таймаут ViewModel задаётся через processingTimeoutSeconds.
- В E2E-тестах ShareExtensionManager проверяет только ошибки и успехи обработки, но не таймаут.

### Operation Color & ResultMode Support
- InventoryOperation расширена свойством colorHex (hex-код цвета из палитры).
- Добавлен признак resultMode (clipboard/display) для операций.
- Сериализация/десериализация InventoryOperation поддерживает colorHex и режим обработки результата.
- UI (HomeView, ShareExtensionView) отображает цвет операции и корректно обрабатывает режимы clipboard/display.
- Для Explain результат отображается во всплывающем окне с прокруткой.
- Покрыто unit, UI и e2e тестами (отображение, выбор, сохранение цвета, режимы обработки результата).

- Операция correct теперь не содержит параметра stylePreservationLevel, всегда используется максимальный уровень сохранения стиля.
- UI не отображает элементы для выбора уровня сохранения стиля.

### Onboarding (Welcome Screen Before Consent)
- CraftifyApp использует глобальное состояние AppState (ObservableObject), которое хранит флаг согласия пользователя.
- Если согласие не получено, показывается HowToUseView с чекбоксом и кнопкой согласия.
- После согласия автоматически отображается основной экран HomeView.
- Согласие хранится в App Group UserDefaults через ConsentManager.
- Покрыто e2e-тестом на полный flow: нет согласия → согласие → переход на HomeView.

## Архитектура UI окна шаринга (ShareExtension)

- Весь основной контент (заголовок, результат, список операций) размещён внутри ScrollView.
- Кнопка закрытия закреплена внизу через `.safeAreaInset(edge: .bottom)`, всегда доступна пользователю.
- Оверлеи (индикатор процесса, тост) реализованы через ZStack и не мешают взаимодействию с основным контентом.
- Такой подход обеспечивает:
    - UX: кнопка всегда доступна, даже при длинном контенте
    - Контент не перекрывается кнопкой
    - Поддержка accessibility и адаптация к разным устройствам
- Все изменения покрыты unit- и e2e-тестами, что гарантирует стабильность поведения.
