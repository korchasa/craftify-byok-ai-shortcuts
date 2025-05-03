# План по устранению дублирования и унификации стилей

## Проблемы
- Дублирование палитры цветов в AddOperationViewModel и EditOperationViewModel.
- bottomPadding и horizontalPadding для кнопок совпадают в нескольких местах, но определяются локально.

## Цели
1. Использовать ColorPaletteConstants.palette в AddOperationViewModel и EditOperationViewModel.
2. Вынести единые константы для кнопок (отступы, радиус, цвета) в CraftifyButtonConstants и использовать их во всех вью.
3. Проверить и унифицировать паддинги для кнопок во всех экранах.

## Шаги
- [x] Анализ существующих констант и дублирования
- [x] Рефакторинг ViewModel для палитры
- [x] Рефакторинг паддингов и стилей кнопок
- [x] Проверка и тестирование
- [x] Обновление документации

## Выводы
- Дублирование палитры устранено: теперь используется только ColorPaletteConstants.palette.
- Все параметры кнопок (отступы, радиус, цвета) централизованы в CraftifyButtonConstants и используются во всех вью.
- Проект успешно проходит тесты и статический анализ.
- Документация обновлена.

## Workflow changes after adding test plans and simplifying test command
- [x] Introduced testPlans (Unit, E2E, All) in project.yml
- [x] Created AllTests scheme leveraging testPlans
- [x] Refactored ./run: added _test_plan helper and 'all' command
- [x] Simplified 'test' dispatch to accept plan and optional test identifier
