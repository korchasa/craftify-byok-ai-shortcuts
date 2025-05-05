# Проблема: поля свойств не меняются при смене типа операции, нельзя создать операцию без смены типа

## Анализ и гипотезы
- В AddOperationView/EditOperationView не используется AddOperationFields/EditOperationFields, поэтому поля для выбранного типа не отображаются.
- В AddOperationViewModel/EditOperationViewModel нет сброса/инициализации полей при смене типа операции.
- selectedKind по умолчанию nil, форма невалидна, если не выбрать тип.
- Лейблы для полей не отображаются, так как они не добавлены в AddOperationFields.

## План исправления (TDD)
1. Добавить компонент AddOperationFields/EditOperationFields в body AddOperationView/EditOperationView.
2. Добавить сброс/инициализацию полей при смене selectedKind в AddOperationViewModel/EditOperationViewModel.
3. Установить selectedKind в значение по умолчанию (первый тип) при инициализации AddOperationViewModel.
4. Добавить лейблы к каждому полю в AddOperationFields.
5. Добавить/обновить тесты:
   - Проверить сброс полей при смене типа
   - Проверить валидность формы для каждого типа
   - Проверить отображение лейблов
6. Прогнать тесты, убедиться в исправлении.

---
- [x] Вставить AddOperationFields/EditOperationFields в body
- [x] Реализовать сброс/инициализацию полей при смене типа
- [ ] Установить selectedKind по умолчанию
- [ ] Добавить лейблы к полям
- [ ] Добавить/обновить тесты
- [ ] Прогнать тесты
