# Текущая задача

**Запрос:** убрать из операции correct свойство style preservation. Пусть всегда стиль сохраняется (максимально).

## Анализ
- В коде операции correct был параметр stylePreservationLevel, который пользователь мог выбирать (Stepper в UI, поле в ViewModel, сериализация в CorrectParams).
- Требуется: убрать возможность выбора, всегда использовать максимальный стиль (3).
- Необходимо:
  - Убрать Stepper из AddOperationView и EditOperationView.
  - В ViewModel всегда выставлять stylePreservationLevel = max.
  - Везде, где создаётся correct-операция, жёстко подставлять максимальный стиль.
  - Обновить тесты (unit, e2e), убрать проверки изменения этого параметра.

## Шаги
- [x] Удалён Stepper из AddOperationView и EditOperationView.
- [x] В AddOperationViewModel и EditOperationViewModel stylePreservationLevel всегда = max.
- [x] В makeOperation для correct всегда подставляется максимальный стиль.
- [x] Тесты обновлены: убраны проверки изменения stylePreservationLevel, корректно проверяется только максимальный стиль.
- [x] Прогнал unit и e2e тесты — всё зелёное.

## Итог
- Операция correct всегда сохраняет стиль максимально.
- UI не предлагает пользователю выбирать уровень сохранения стиля.
- Все тесты проходят, проект в рабочем состоянии.

---
