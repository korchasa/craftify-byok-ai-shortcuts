# Задача
Убрать operation_param_target_language, operation_param_complexity_level, operation_param_style_preservation и operation_param_detail_level на главном экране и экране шаринга. Значения должны остаться, например, не "Detail level: intermidiate", а просто "Intermidiate".

## Анализ
- Подписи параметров формируются в HomeView (operationParamsDescription) и ShareExtensionView (operationDisplayName).
- В формах добавления/редактирования операции подписи нужны, но не на главном и шаринг экранах.

## План
1. Найти и изменить функции, формирующие подписи параметров на главном экране (HomeView) и экране шаринга (ShareExtensionView).
2. Удалить подписи, оставить только значения.
3. Проверить, что формы Add/EditOperationView не затронуты.
4. Запустить все тесты и убедиться в отсутствии ошибок.
5. Зафиксировать изменения в документации.

## Выполнено
- Найдены и изменены функции operationParamsDescription (HomeView) и operationDisplayName (ShareExtensionView): теперь отображаются только значения параметров.
- Проверено, что AddOperationView и EditOperationView используют подписи только в формах.
- Запущены unit-тесты, все прошли успешно.

## Следующее действие
- Обновить документацию и завершить задачу.