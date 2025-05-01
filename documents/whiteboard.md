Запрос: сделать так, чтобы тесты и сборка падали при любых ворнингах компилятора и SwiftLint.

Анализ:
- Для SwiftLint есть флаг --strict (или strict: true в конфиге), который завершает выполнение с ошибкой при warning.
- Для компилятора Swift есть настройка SWIFT_TREAT_WARNINGS_AS_ERRORS: YES, которая завершает сборку с ошибкой при warning.

План действий:
1. Вызов swiftlint lint --strict в функции lint скрипта run (без --quiet).
2. Добавить SWIFT_TREAT_WARNINGS_AS_ERRORS: YES в project.yml для всех targets.
3. Обновить правило в code-style-swift.md: все ворнинги считаются ошибками.
4. Проверить: запустить ./run test и убедиться, что ворнинги приводят к ошибке.
5. Обновить документацию при необходимости.

Выполнено:
- Вызов swiftlint lint --strict добавлен.
- SWIFT_TREAT_WARNINGS_AS_ERRORS: YES добавлен в project.yml.
- Правило добавлено в code-style-swift.md.
- Документация проверена.

Задача завершена.
