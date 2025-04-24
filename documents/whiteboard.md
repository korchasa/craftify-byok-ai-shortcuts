# План и прогресс: реорганизация run для CI/CD

## Цель
Привести скрипт run к атомарному виду: только команды для локальной разработки и CI/CD, без агрегирующих ci:feature, ci:develop и т.д. Все необходимые команды должны быть доступны для вызова из GitHub Actions.

## Шаги
1. Проанализировать текущий run на наличие устаревших команд и их описание в usage.
2. Удалить команды ci:feature, ci:develop, ci:release, ci:hotfix, ci:main из usage и case.
3. Проверить, что все атомарные команды для задач feature/develop/release/hotfix/main присутствуют:
   - test:lint, test:format, build:simulator, test:unit, test:coverage, pr-check, analyze, archive, export-ipa, deploy:testflight, deploy:internal, deploy:adhoc, deploy:appstore, generate-changelog, notify, monitor-setup, bump-version, size-report, build, dev, clean, logs
4. Обновить usage, чтобы отражать только актуальные команды.
5. Зафиксировать изменения и подготовить к обновлению GitHub Actions.
6. Обновить workflow GitHub Actions для использования атомарных команд run и разделения по веткам.

## Прогресс
- [x] Устаревшие команды ci:* удалены из usage и case
- [x] usage обновлен, отражает только атомарные команды
- [x] Все необходимые команды для feature/develop/release/hotfix/main присутствуют
- [x] Подготовить обновление workflow GitHub Actions
- [x] Workflow GitHub Actions обновлен: для каждой ветки используются атомарные команды run, структура jobs соответствует схеме из ТЗ
