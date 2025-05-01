# Whiteboard

## Проверка реализации и тестирования операций Craftify

### Запрос пользователя
Проверь операции, что они полностью реализованы. Напиши тесты на их работу с llm

### Анализ
- Все 4 операции (translate, simplify, correct, explain) реализованы как структуры, соответствующие протоколу OperationType.
- Для каждой операции реализованы методы isValid, makeInventoryOperation, buildRequest (заглушка), parse.
- Генерация InventoryOperation корректна для всех типов.
- Вся обработка текста через LLM происходит через ProcessingManager → LLMAPIClient.
- Покрытие тестами:
  - Есть unit-тесты на параметры и сериализацию (OperationModelsTests).
  - Есть unit/e2e тесты на ViewModel'и, создание/валидацию/редактирование операций.
  - Есть интеграционные тесты LLMAPIClient (LLMAPIClientTests, LLMAPIClientIntegrationTests).
  - ✅ Добавлены unit-тесты, проверяющие интеграцию OperationType с LLMAPIClient (сквозной путь: OperationType → InventoryOperation → ProcessingManager → LLMAPIClient).
  - ⚠️ Edge-case: при пробросе ошибки через completion теряется конкретный тип enum (type-erasure), из-за чего pattern matching в XCTest не всегда работает. Требует дальнейшего анализа (возможно, баг XCTest или нюанс bridging).

### План
1. Для каждого OperationType (translate, simplify, correct, explain) добавить unit-тест:
   - Создать InventoryOperation через makeInventoryOperation.
   - Передать в ProcessingManager с мок-LLMAPIClient (или stub-сессию).
   - Проверить, что результат соответствует ожидаемому (ответ LLM).
2. Проверить edge-cases: невалидные параметры, ошибки LLM, отмена запроса.
3. Обновить документацию по тестированию операций.

### Прогресс
- [x] Проверить существующие реализации и тесты
- [x] Добавить unit-тесты на интеграцию OperationType с LLM
- [ ] Проверить edge-cases
- [ ] Обновить документацию

// Edge-case: см. выше — требуется дополнительное исследование type-erasure ошибок в XCTest.

