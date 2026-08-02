---
date: "2026-08-02"
status: done
implements: [FR-UX.PROVIDER-ERRORS, FR-UX.RETRY]
tags: [share-extension, errors, providers, localization]
related_tasks: [2026/07/ux-improvement-backlog.md]
---
# Понятные сообщения на любой ответ провайдера [ANC:task:2026-08-provider-error-taxonomy]

## Goal

Пользователь платит за ключ сам и остаётся один на один с ответом провайдера. Если расширение
на любой отказ показывает «Произошла неизвестная ошибка», человек не понимает, кончились ли у него
деньги, не тот ли ключ, слишком ли длинный текст, — и не знает, что делать дальше. Каждый отказ
должен называть причину и следующий шаг.

## Overview

### Context

Разбор начался с вопроса, как ошибки провайдера выглядят для пользователя. Выяснилось, что
`LLMAPIClientError.userFacingError` — заготовка с локализованными сообщениями — не вызывалась нигде
в рабочем коде: `ShareExtensionManager` пытался привести ошибку к `UserFacingError`, приведение не
срабатывало, и наружу уходила «неизвестная ошибка». Точный тип ошибки при этом писался в лог, но до
экрана не доходил.

### Current State

- Разбор ответа был раскопирован по четырём клиентам (`OpenAIAPIClient`, `ClaudeAPIClient`,
  `MistralAPIClient`, `OpenRouterAPIClient`) и знал только 401, 429 и 500; у OpenAI серверной
  ошибкой считался ровно код 500, поэтому 502 и 503 читались как «ошибка разбора ответа».
- Повторы уходили на любую ошибку, включая неверный ключ: три попытки с паузами 1 и 2 секунды.
- Кнопка «Повторить» показывалась по ключу ошибки, а ключ у всех отказов был один и тот же —
  «неизвестная ошибка», которая считается повторяемой.

### Constraints

- Формы тел ответов берём из документации провайдеров, а не по памяти (правило Data-First).
- Ключи локализации должны совпадать во всех 11 языках бандла расширения — это проверяет `./run check`.
- Тесты правят исходный код, а не ожидания: заготовку сообщений не переписываем, а подключаем.

## Definition of Done

- [x] FR-UX.PROVIDER-ERRORS: любой отказ провайдера показывается своим локализованным сообщением
      с советом, а не «неизвестной ошибкой»
  - Test: `src/ShareExtension/UnitTests/ShareExtensionManagerTests.swift::testProcess_ProviderErrorKeepsItsUserFacingMessage`
  - Evidence: `./run test ShareExtensionUnitTests`
- [x] FR-UX.PROVIDER-ERRORS: коды и тела всех четырёх провайдеров раскладываются в одну таксономию,
      включая ошибку внутри ответа с кодом 200
  - Test: `src/ShareExtension/UnitTests/LLMHTTPErrorMapperTests.swift::test_openRouter_errorInsideSuccessBody`
  - Evidence: `./run test ShareExtensionUnitTests`
- [x] FR-UX.PROVIDER-ERRORS: объяснение провайдера видно под сообщением, когда он отклонил запрос
  - Test: `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift::testProcess_BadRequestShowsProviderExplanation`
  - Evidence: `./run test ShareExtensionUnitTests`
- [x] FR-UX.RETRY: повтор предлагается и выполняется только там, где он что-то меняет
  - Test: `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift::testProcess_ProviderUnauthorizedShowsKeyErrorWithoutRetry`
  - Evidence: `./run test ShareExtensionUnitTests`
- [x] Переводы добавлены во все 11 языков расширения без расхождения ключей
  - Test: `run::check_localization (сверка ключей по 3 бандлам)`
  - Evidence: `./run l10n`

## Solution

1. Подключить `LLMAPIClientError.userFacingError` в `ShareExtensionManager` — один общий метод
   приведения ошибки к виду для пользователя, вместо двух копий приведения к `UserFacingError`.
2. Вынести разбор ответа в `LLMHTTPErrorMapper`: код ответа решает первым, признаки в теле
   (`error.code`, `error.type`, `metadata` у OpenRouter, `detail` у Mistral) уточняют неоднозначные
   коды. Отдельный вход для ошибки внутри ответа с кодом 200.
3. Расширить `LLMAPIClientError` до полной таксономии: нехватка средств, отказ в доступе, модерация,
   переполнение контекста, таймаут, отказ запроса с текстом провайдера.
4. Добавить `isRetryable` и прекратить повторы там, где они бесполезны; согласовать с ним набор
   ключей, при которых модель представления показывает кнопку «Повторить».
5. Показывать объяснение провайдера (`providerDetail`) под сообщением для отклонённого запроса и
   неизвестной модели.
6. Добавить 10 ключей локализации во все 11 языков расширения.
