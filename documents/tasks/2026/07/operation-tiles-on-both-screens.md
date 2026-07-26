---
date: "2026-07-26"
status: done
implements: [FR-UX.OPERATION-TILES, FR-UX.TILE-ARRANGE, FR-UX.SHARE-INPUT-PREVIEW]
tags: [ux, home, share-extension, design, drag-and-drop, localization]
related_tasks: [2026/07/ux-improvement-backlog.md]
---
# Одинаковые плитки операций на главном экране и на экране выбора [ANC:task:2026-07-operation-tiles-on-both-screens]

## Goal

Главный экран и экран выбора трансформации — две половины одного сценария. На главном экране
пользователь задаёт, какие команды существуют, как они настроены и в каком порядке стоят; в
расширении он этим пользуется. Сейчас экраны выглядят по-разному: в приложении — список строк, в
расширении — сетка карточек, и одна и та же настройка показывается по-разному. Из-за этого
расстановка плиток в приложении не предсказывает то, что пользователь увидит, когда поделится
текстом. Плюс расширение вообще не показывает текст, который собирается обработать.

## Overview

### Context

Референс дизайна: проект Claude Design `3bf646fb-b22d-409a-be29-fb7ffb27935d`, файл
`Операции - варианты.dc.html`, вариант `11b` («Операции — плитки 64 pt, иконка слева»). На макете —
шторка расширения: сверху мелкая прописная подпись и текст, которым поделились, ниже сетка в две
колонки из плиток высотой 64 pt: иконка слева, название жирным, значение настройки второй строкой
помельче.

Требования пользователя дословно:

1. «Нужно доработать экран списка и экран выбора трансформации. На экране списка пользователь задает
   настройку, на экране выбора - использует ее. Еще на экране выбора наверху должен быть текст над
   которым работаем».
2. «экран списка(основной экран) нужно было тоже доработать так же. На основном экране пользователь
   должен задавать список команд и их расположение на экране выбора. Они должны быть одинаковыми по
   выводу плиток».
3. «на основном экране плитки должны быть перетаскиваемыми, после нажати на edit. И они должны
   дрожать, и иметь минус, по аналогии с иконками приложений в ios».
4. «плитки должны прижиматься к низу, чтобы было удобно выбирать одной рукой».
5. «Нужно перейти от списка команд на ячейки. Должна быть возможность поставить плитку на любое
   место, а не просто менять их порядок. В режиме редактирования на пустых местах должна рисоваться
   кнопка "+ добавить" на всех пустых ячейках».
6. «новые ячейки должны создаваться не внизу, а вверху экрана, чтобы удобно было работать одной
   рукой».
7. «При перетаскивании выглядит некрасиво. Видно белый прямоугольник, обрезается кнопка удаления.
   Можно убирать кнопку удаления при перетаскивании»; затем — «нужно убрать кнопку удаления при
   перетаскивании и починить цвет фона, чтобы было не видно этот прямоугольник».
8. «давай добавим еще автоматический переход в режим редактирования при долгом нажатии. Чтобы было
   как с иконками в ios».

### Current State

Рабочее дерево уже содержит незакоммиченную частичную реализацию первого и второго требований. Она
**не собирается**: `HomeView` ссылается на типы `OperationTileButton` и `OperationDropDelegate`,
которых в репозитории нет. Это состояние — отправная точка задачи, а не готовый результат.

Что есть на сегодня:

- `src/Common/Sources/OperationTileView.swift`, `OperationTileConstants.swift`,
  `OperationGridLayout.swift` — общая плитка и геометрия сетки, уже используются расширением.
- `src/Common/Sources/Models/OperationDisplay.swift` — общий форматтер названия и значения настройки.
  `SummarizeLengthDisplay` переехал из MainApp в Common, чтобы расширение показывало локализованную
  подпись длины, а не каноническую английскую строку из промпта.
- `src/ShareExtension/Sources/ShareExtensionView.swift` — шапка с обрабатываемым текстом и сетка
  плиток; `ShareExtensionViewModel` публикует `inputText` и `isInputURL`.
- `src/MainApp/Sources/HomeView.swift` — сетка плиток начата, но `OperationTileButton` и
  `OperationDropDelegate` не написаны; старый `OperationRowView` остался мёртвым кодом.
- `HomeViewModel` уже умеет `reorderOperations(fromOffsets:toOffset:)` и `removeOperation(at:)` —
  слой данных под перетаскивание и удаление менять не нужно.
- `InventoryOperation.id` вычисляется из `operation + params.hashValue + colorHex`. Две одинаково
  настроенные операции неразличимы: у них совпадают и `id`, и результат `==`. Текущий черновик
  перетаскивания работает по номерам позиций, поэтому «взять не ту плитку» ему не грозит — зато
  SwiftUI не может отличить плитки друг от друга между кадрами: перестановка анимируется подменой
  содержимого, фаза дрожания перескакивает между соседями, а правка операции выглядит как замена
  элемента списка. Устойчивый идентификатор нужен именно для этого, а не для защиты от подмены.
- Локализация: ключи `home_order`, `homeSortHandle`, `homeSortHint` существуют в 11 локалях MainApp,
  но нигде не выводятся — `HomeView.init` только «трогает» их, чтобы Periphery не ругался. Ключей для
  подписи кнопки удаления нет ни в одной локали.
- `src/MainApp/UITests/OperationEditingUITests.swift::testSwipeRevealsDeleteOnListRow` проверяет
  удаление свайпом по строке списка. Со сменой списка на сетку с минусом этот тест теряет смысл.

### Affected Surface

Вывод `surface-scout` дословно:

```
## Surface

**Models / formatters (shared, `src/Common/Sources`)**
- `src/Common/Sources/OperationTileConstants.swift` — geometry constants (columns, tile height, corner radius, spacing) already declared shared "for the main screen and the picker"; a jiggle/minus mode needs new constants (badge size/offset, jiggle amplitude/duration) that belong here to keep both screens' tile geometry identical.
- `src/Common/Sources/OperationTileView.swift:1-65` — the plain (non-editing) tile view used by both screens; must stay untouched/reusable as the "rest" state that the new editable tile wraps or matches visually, since parity is the whole point of the request.
- `src/Common/Sources/OperationGridLayout.swift` — shared grid column definition; consumed by both `HomeView` and `ShareExtensionView` grids, so any layout change for edit mode (e.g., reserving space for the minus badge) affects both call sites even though only the list screen edits.
- `src/Common/Sources/Models/OperationDisplay.swift` (untracked, new) — shared `title(for:)`/`settingValue(for:)` formatter now used by both `HomeView.OperationRowView` and `ShareExtensionView.displayOperationTitle()`; still referenced by dead code (`OperationRowView`) that the drag/jiggle rewrite makes obsolete.
- `src/Common/Sources/Models/SummarizeLengthDisplay.swift` (staged as new file, moved from `src/MainApp/Sources/`) — feeds `OperationDisplay.settingValue`; git status shows the old `src/MainApp/Sources/SummarizeLengthDisplay.swift` deleted in the working tree, i.e. this move is mid-flight and affects both screens' setting text.
- `src/Common/Sources/Models/InventoryOperation.swift`, `InventoryManaging.swift`, `InventoryManager.swift`, `InventoryManagerStub.swift` — the underlying persisted list/order that `HomeViewModel.reorderOperations`/`removeOperation` mutate; drag-reorder and minus-delete both go through this layer, so its ordering/removal contract is exercised by the new gesture, not just tapped buttons.

**Screens**
- `src/MainApp/Sources/HomeView.swift:97-137` — `operationsList`/`operationTile` already call `OperationTileButton(...)` and `OperationDropDelegate(...)` which **do not exist anywhere in the repository** (`grep` for `struct OperationTileButton` / `struct OperationDropDelegate` returns nothing) — the file does not compile in the current working tree. This is the direct implementation site for "draggable after Edit, jiggle, minus button."
- `src/MainApp/Sources/HomeView.swift:197-266` — `private struct OperationRowView` (list-row style with circle icon) is now dead code: `operationsList` no longer references it after the switch from `List`+`.onMove`/`.onDelete` to `LazyVGrid`+`onDrag`/`onDrop`. Its `settingAccessory`, `accessibilityIdentifier("operation_row_...")` behavior needs to be reconciled with (or removed in favor of) the new tile.
- `src/MainApp/Sources/HomeView.swift:13-15` — `@State private var editMode` and new `@State private var draggingIndex` drive both the Edit toggle and the drag state; `EditButton()` in `titleBar` (line 168) is the trigger the request calls "after pressing edit."
- `src/MainApp/Sources/HomeViewModel.swift:31-36` — `reorderOperations(fromOffsets:toOffset:)` already exists and is called from the (currently undefined) drop delegate; `removeOperation(at:)` (line 21-24) is the target for the new minus button, replacing the old swipe-to-delete UX.
- `src/ShareExtension/Sources/ShareExtensionView.swift:181-200` — `operationsGrid`/`operationButton(for:)` render `OperationTileView` (the shared, non-editable variant) — this is the "selection screen" that must render tiles identically to what the list screen produces, but never enters edit/jiggle/drag mode; any tile-geometry change made for the minus badge must not leak into this button-only rendering.
- `src/ShareExtension/Sources/ShareExtensionView.swift:66-93` — `inputPreview` (the "text we're working on" header above the grid) — already implemented per the second-to-last user turn ("на экране выбора наверху должен быть текст").
- `src/ShareExtension/Sources/ShareExtensionViewModel.swift` — publishes `inputText`/`isInputURL` consumed by `inputPreview`; producer side of that preview text.
- `src/MainApp/Sources/AddOperationView.swift`, `EditOperationView.swift` — not modified themselves, but they are the sheets `HomeView` opens on tile tap (`onEdit`); once tiles gain a jiggle/minus mode, the "tap opens edit sheet" vs. "tap does nothing while jiggling" interaction split needs to be resolved here (`isEditing` already `.disabled(isEditing)` on the old row).

**Resources / localization**
- `src/MainApp/Resources/*.lproj/Localizable.strings` (11 locales) — `home_order`, `homeSortHandle`, `homeSortHint` keys exist and are referenced only via `_ = L10n.homeSortX` no-ops in `HomeView.init` (lines 26-28) "to keep Periphery from flagging them unused" — i.e., they were added for the drag feature but are not yet wired into any accessibility hint/label on an actual view.
- `src/MainApp/Resources/en.lproj/Localizable.strings:11-12` — `home_delete` / `home_delete_confirm` strings back the current swipe-to-delete UI; a minus-button delete flow (with or without confirmation) is a parallel/competing consumer of these same keys.
- `src/ShareExtension/Resources/*.lproj/Localizable.strings` (11 locales) — modified this session for `share_input_caption`/`share_input_caption_link` and summarize sentence-count keys; the task doc flags a pt.lproj mismatch between MainApp and ShareExtension bundles that the CI key-parity gate checks.
- No existing `minus`/`jiggle`/`wiggle`/`shake` localization keys or accessibility strings found anywhere — a new minus/delete-badge accessibility label would be a net-new resource surface, not a reuse of `home_delete`.

**Tests**
- `src/MainApp/UITests/OperationEditingUITests.swift:46-57` — `testSwipeRevealsDeleteOnListRow` asserts swipe-to-reveal-Delete on `operation_row_translate`; its own doc comment says "удаление живёт на списке (свайп), а не в форме" — this directly conflicts with an iOS-style minus-button/jiggle delete model and targets an identifier (`operation_row_...`) tied to the now-dead `OperationRowView`.
- `src/MainApp/UITests/OperationEditingUITests.swift:21-44` — `testColorPickerPopoverOpensAndSelects` also starts by tapping `operation_row_translate` as a button; depends on the same identifier surviving the tile rewrite.
- `src/MainApp/UnitTests/HomeViewTests.swift:24-28` — `testHomeViewRendersMainElements` just instantiates `HomeView` inside `UIHostingController`; will fail to compile/render as long as `OperationTileButton`/`OperationDropDelegate` are undefined.
- `src/MainApp/UnitTests/HomeViewModelTests.swift` — exercises `reorderOperations`/`removeOperation` at the view-model level; the reorder/removal contract these tests assert on is exactly what a drag/minus UI must call.
- `src/Common/UnitTests/OperationDisplayTests.swift` (untracked, new) — covers `OperationDisplay.settingValue`, the parity formatter shared by both screens' tiles.
- `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift` (modified) — covers `updateInputText` publishing the preview/URL flag.
- No existing test file targets `OperationTileButton`, `OperationDropDelegate`, or any jiggle/drag-after-edit behavior on the grid — this is a net-new test surface with no current owner.

**Project configuration / docs**
- `documents/srs.md` (modified, uncommitted) — new `FR-UX.OPERATION-SETTING-PARITY` and `FR-UX.SHARE-INPUT-PREVIEW` requirement blocks already marked `Status: [x]`, each carrying `[ANC:fr:...]` anchors and acceptance test references; a third requirement for "draggable/jiggle/minus tiles on the list screen" has no corresponding SRS entry yet.
- `documents/index.md` (modified, uncommitted) — index rows for the same two `[REF:fr:...]` anchors; same gap for the drag/jiggle behavior.
- `documents/tasks/2026/07/operation-setting-parity-and-preview.md` (untracked) — the task doc governing the first two user turns (parity + input preview); its "Follow-ups" section explicitly scopes out inline setting edits but says nothing about drag/jiggle/delete, i.e., the third user turn falls entirely outside this task's Definition of Done.
- `src/MainApp/Sources/HomeView.swift:95` / `src/ShareExtension/Sources/ShareExtensionView.swift:62` — `// [REF:fr:ux.operation-tiles]` and `// [REF:fr:ux.share-input-preview]` anchor comments in code that must stay in sync with whatever SRS/index entries end up describing the new drag/jiggle/minus requirement.
- `AGENTS.md` (project convention file, not yet inspected in detail this pass but referenced by CLAUDE.md tree) — governs "one declaration per file" / SwiftLint `opt_in_rules: all` constraints noted in the task doc; the still-missing `OperationTileButton` and `OperationDropDelegate` types would each need their own file under this convention, plus a `closures ≤ 30 lines` constraint that the drag-delegate closures must respect.

## Queries used
- `find` over `./src` (excluding build/DerivedData/Derived/.build) for the full source tree and directory map.
- `grep -rn "transform|shortcut"` and manual directory listing of `src/MainApp/Sources`, `src/Common/Sources`, `src/ShareExtension/Sources`.
- `grep -rn "OperationTileButton|OperationDropDelegate"` across `src/**/*.swift` (confirms undefined symbols).
- `grep -rln "struct OperationTileButton|struct OperationDropDelegate|class OperationDropDelegate"` project-wide.
- `git status`, `git diff --stat`, `git diff src/MainApp/Sources/HomeView.swift`, `git diff documents/srs.md documents/index.md` — to see what is already mid-edit vs. untouched.
- Read: `HomeView.swift`, `HomeViewModel.swift`, `OperationTileView.swift`, `OperationGridLayout.swift`, `OperationTileConstants.swift`, `ShareExtensionView.swift`, `documents/tasks/2026/07/operation-setting-parity-and-preview.md`.
- `grep -n "homeSortHint|homeSortHandle|homeOrder|home_sort_hint|home_sort_handle|home_order"` across the repo.
- `grep -n "delete|remove|minus"` in `en.lproj/Localizable.strings`; `find` for `*Snapshot*` test files; `grep -rln "wiggle|jiggle|shake|rotationEffect"` across `src`.
- `find src/MainApp/UITests`, `find . -iname "*HomeViewModel*Test*"`, `find . -iname "*HomeView*Test*"`.
- Read: `OperationEditingUITests.swift`, `HomeViewTests.swift`.

## Not examined (budget)
- `src/MainApp/UnitTests/HomeViewModelTests.swift` — listed but not opened in full; likely relevant for reorder/removal assertions.
- `AGENTS.md` at repo root — not opened; referenced only via CLAUDE.md summary, may contain concrete file-per-declaration/SwiftLint rules that bound how the new drag types must be split into files.
- `documents/srs.md` and `documents/index.md` in full (only the diff was inspected, not the surrounding unmodified sections that might already reference operation-tiles/drag anchors).
- Palette files (`ColorPaletteFactory`, `MainAppColorPaletteProviding`, dark/light palettes) — not checked for whether they'd need a new color token for the jiggle/minus badge (e.g., a red delete-badge color akin to iOS).
- `FormStyleConstants.swift`, `CraftifyButtonConstants.swift` — only referenced, not read in full, though `HomeView` uses their padding constants around the grid.
- `.github/workflows` CI config — not checked for whether it runs the now-broken `OperationEditingUITests` or the whole-project `./run check` gate that would surface the current compile failure.
- Design MCP source files (`_ds_bundle.js`, `styles.css`, `support.js`, the `.dc.html` design doc) were not fetched/read in this pass — I treated the design reference only via the already-existing task doc's paraphrase (design project `3bf646fb-b22d-409a-be29-fb7ffb27935d`, file "Операции - варианты.dc.html", option 11b), not by pulling the MCP content directly.
- `src/MainApp/Sources/Components/*` (`CommonFormContainer`, `ModelPickerView`, `OperationColorPicker`) — not checked for reusable drag/badge affordances that might already exist elsewhere in the app.

## Could not rule out
- Whether `OperationTileButton`/`OperationDropDelegate` are meant to live in `src/Common/Sources` (shared) or `src/MainApp/Sources` (list-only) — this affects whether the ShareExtension target picks them up unintentionally; I have no evidence of an existing stub in either location.
- Whether the "minus" delete on the tile should reuse `home_delete_confirm` (confirmation dialog) or skip confirmation like iOS springboard — no code or string currently distinguishes these, so I can't confirm which consumer would be affected.
- Whether `src/MainApp/UnitTests/HomeViewModelTests.swift` already contains reorder/removal tests that would need updating for a drag-driven flow versus new tests being purely additive — file was found but not opened.
- Whether CI (`.github/workflows`) currently blocks merges on `OperationEditingUITests`, meaning the present broken build state is already failing pipelines — not verified.
```

Расстановка по объединению моего списка и списка скаута:

- `src/Common/Sources/OperationTileView.swift` — covered-by шаг 1 решения (плитка получает режим правки, покой остаётся прежним).
- `src/Common/Sources/OperationTileConstants.swift` — covered-by шаг 1 (константы бейджа и дрожания).
- `src/Common/Sources/OperationGridLayout.swift` — covered-by шаг 1 (колонки не меняются, бейдж рисуется overlay внутри клетки).
- `src/Common/Sources/Models/OperationDisplay.swift`, `SummarizeLengthDisplay.swift` — covered-by DoD FR-UX.OPERATION-TILES.
- `src/Common/Sources/Models/InventoryOperation.swift`, `InventoryManager.swift` — covered-by шаг 1 (устойчивый `UUID` и миграция при загрузке).
- `src/Common/Sources/Models/InventoryManaging.swift`, `InventoryManagerStub.swift` — not affected — протокол и заглушка работают с массивом операций по индексам, сигнатуры не меняются; заглушка хранит инвентарь в памяти и не декодирует JSON.
- `src/MainApp/Sources/EditOperationViewModel.swift` — covered-by шаг 1 (`makeOperation()` переносит идентификатор исходной операции).
- `src/MainApp/Sources/HomeView.swift` — covered-by шаги 2–4 (сетка, режим правки, перетаскивание, удаление); мёртвый `OperationRowView` удаляется.
- `src/MainApp/Sources/HomeViewModel.swift` — covered-by шаг 4 (вызовы `reorderOperations`/`removeOperation`; сигнатуры не меняются).
- `src/ShareExtension/Sources/ShareExtensionView.swift` — covered-by шаг 1 (использует ту же плитку в состоянии покоя) и DoD FR-UX.SHARE-INPUT-PREVIEW.
- `src/ShareExtension/Sources/ShareExtensionViewModel.swift`, `ShareExtensionViewHeight.swift` — covered-by DoD FR-UX.SHARE-INPUT-PREVIEW.
- `src/MainApp/Sources/AddOperationView.swift`, `EditOperationView.swift` — not affected — сами файлы не меняются: тап по плитке открывает тот же лист, а в режиме правки кнопка выключена (`.disabled(isEditing)` уже в текущем коде `HomeView.swift:259`).
- `src/MainApp/Resources/*.lproj` (11 локалей) — covered-by шаг 5: новых ключей не заводим, а существующие `home_delete`, `home_delete_confirm`, `home_sort_hint`, `home_sort_handle`, `home_order` наконец начинают выводиться; обходной приём `_ = L10n.homeSortX` из `init` убирается (шаг 4).
- `src/ShareExtension/Resources/*.lproj` (11 локалей) — covered-by DoD FR-UX.OPERATION-TILES (`sentence_count_*`, `share_input_caption*`) — уже добавлены, остаётся держать паритет ключей.
- `src/MainApp/UITests/OperationEditingUITests.swift::testSwipeRevealsDeleteOnListRow` — covered-by шаг 6: тест переписывается под минус в режиме правки, потому что свайпа по строке больше нет.
- `src/MainApp/UITests/OperationEditingUITests.swift::testColorPickerPopoverOpensAndSelects` и `EditOperationPromptUITests` — covered-by шаг 2: идентификатор `operation_row_<kind>` сохраняется на плитке.
- `src/MainApp/UnitTests/HomeViewTests.swift`, `HomeViewModelTests.swift` — covered-by шаг 6.
- `documents/srs.md`, `documents/index.md` — covered-by шагами 5b/5c этого плана.
- `src/Common/Sources/Models/OperationType.swift` (протокол `makeInventoryOperation`) и его пять
  реализаций — not affected — идентификатор доносится вызовом `.with(id:)` уже после фабрики
  (`EditOperationViewModel.swift:140`), поэтому сигнатуру протокола менять не нужно.
- `src/Common/Sources/Models/InventoryManager.swift:92,113,121,129,137` (`fillWithDefaultOperationsIfNeeded`)
  и `src/MainApp/Sources/AddOperationViewModel.swift:58` — not affected — новым операциям подходит
  идентификатор, который фабрика раздаёт по умолчанию.
- `src/ShareExtension/UnitTests/ProcessingManagerLLMIntegrationTests.swift` (8 вызовов
  `makeInventoryOperation`) и `ShareExtensionViewModelTests.swift:107,148` — not affected — сигнатура
  фабрики не меняется, вызовы остаются как есть.
- `src/Common/UnitTests/CustomPromptTests.swift:32`, `src/Common/UnitTests/OperationModelsTests.swift:32,45`
  — covered-by шаг 1 — они декодируют голым `JSONDecoder()`, поэтому `init(from:)` обязан работать без
  контекста миграции в `userInfo`.
- `documents/tasks/2026/07/operation-setting-parity-and-preview.md` — not affected — черновик задачи удалён при создании этой; двух документов на одни требования больше нет, ссылки в SRS ведут сюда.
- `AGENTS.md` — not affected — правила остаются как есть; раздел Constraints их только пересказывает, файл не меняется.
- `src/ShareExtension/Sources/ShareExtensionViewConstants.swift` — covered-by шаг 3 — константы плитки уже переехали в `OperationTileConstants`, здесь остаются только отступы шапки и оверлея прогресса.
- `.github/workflows/ci.yml` — not affected — воркфлоу крутится на `ubuntu-latest` и делает только `gitleaks detect`; ни сборки, ни тестов там нет, поэтому новые тесты его не касаются. Обратная сторона: UI-тесты не гоняет никто, кроме ручного запуска схемы `UITests`.
- Палитра (`MainAppColorPaletteProviding` и реализации) — not affected — по решению пользователя бейдж красится системным красным, отдельный токен не заводится.
- Файлы дизайн-системы из Claude Design (`_ds_bundle.js`, `styles.css`, `support.js`) — not affected — это веб-стили макета, в SwiftUI-приложение не переносятся; из макета берётся только геометрия варианта 11b.

### Constraints

- Deployment target — iOS 16.0. `.draggable`/`.dropDestination` доступны с iOS 16, но в `LazyVGrid`
  ведут себя нестабильно; связка `.onDrag`/`.onDrop(of:delegate:)` работает начиная с iOS 13/14 и
  надёжнее.
- Дрожание обязано выключаться при включённом «Уменьшении движения»: `@Environment(\.accessibilityReduceMotion)`.
  Иначе анимация нарушает системную настройку доступности.
- SwiftLint работает с `opt_in_rules: all`: одна декларация на файл, тела замыканий ≤ 30 строк,
  документируются все публичные объявления.
- Паритет ключей локализации по 11 локалям в трёх бандлах проверяется в `./run check` — новый ключ
  добавляется сразу во все локали.
- Канонические значения длины резюме остаются английскими с дефисом: они уходят в промпт LLM.
  Локализуется только подпись.
- Порядок и состав операций хранятся в App Group (`group.dev.korchasa.Craftify`) и читаются
  расширением. Любое изменение схемы `InventoryOperation` требует миграции: у пользователей уже есть
  сохранённые операции.
- `src/Common/Sources/**` компилируется в оба таргета, поэтому вид плитки не должен зависеть от
  протоколов палитры конкретного таргета — цвета передаются параметрами.

Решения пользователя, принятые до выбора варианта:

- Удаление по минусу спрашивает подтверждение. Переиспользуются существующие ключи `home_delete` и
  `home_delete_confirm` — они уже есть во всех 11 локалях MainApp. Причина: операцию с правленым
  системным промптом восстановить нельзя.
- Бейдж с минусом красится системным красным поверх плитки, как в iOS. Отдельный токен в палитре
  MainApp не заводим.

## Definition of Done

- [x] FR-UX.OPERATION-TILES: главный экран и экран выбора рисуют операции одной и той же плиткой —
      иконка слева, название, значение настройки — и одинаковое локализованное значение настройки
      (для резюме — подпись, а не каноническая строка промпта).
  - Test: `src/Common/UnitTests/OperationDisplayTests.swift::testSummarizeShowsLocalizedLabelNotCanonicalValue`
  - Evidence: `./run check`
- [x] FR-UX.TILE-ARRANGE: после нажатия Edit плитки на главном экране дрожат, показывают кнопку с
      минусом и перетаскиваются; новый порядок сохраняется и применяется на экране выбора.
  - Test: `src/MainApp/UITests/OperationEditingUITests.swift::testEditModeShowsDeleteBadgeAndRemovesTile`
  - Evidence: `tuist test UITests --configuration Debug` (UI-тесты живут в отдельной схеме и в `./run check` не входят; прогон повторяем — тесты стартуют с `-CraftifyResetInventory`)
- [x] FR-UX.TILE-ARRANGE: нажатие на минус спрашивает подтверждение (`home_delete_confirm`), и
      операция исчезает только после согласия.
  - Test: `src/MainApp/UITests/OperationEditingUITests.swift::testDeleteBadgeAsksConfirmationBeforeRemoving`
  - Evidence: `tuist test UITests --configuration Debug`
- [x] FR-UX.TILE-ARRANGE: перестановка плитки — чистая функция над списком операций, проверяемая без UI:
      плитка встаёт на пустую ячейку, а занятую меняет местами со своей.
  - Test: `src/Common/UnitTests/OperationGridTests.swift::testPlaceSwapsWithTheOperationAlreadyThere`
  - Evidence: `./run check`
- [x] FR-UX.TILE-ARRANGE: дрожание выключено, когда в системе включено «Уменьшение движения».
  - Test: `src/Common/UnitTests/OperationTileWiggleTests.swift::testAmplitudeIsZeroWhenReduceMotionOn`
  - Evidence: `./run check`
- [x] FR-UX.TILE-ARRANGE: идентификатор операции переживает правку настройки и перестановку — плитка
      остаётся той же самой, а не подменяется новой.
  - Test: `src/MainApp/UnitTests/InventoryOperationIdentityTests.swift::testIdentifierSurvivesEditAndReorder`
  - Evidence: `./run check`
- [x] FR-UX.TILE-ARRANGE: сохранённые до обновления операции получают идентификатор без потери данных,
      ровно один раз и только со стороны приложения.
  - Test: `src/Common/UnitTests/InventoryOperationMigrationTests.swift::testLegacyRecordsGetStableIdentifiersOnce`
  - Evidence: `./run check`
- [x] FR-UX.TILE-ARRANGE: экран — это сетка ячеек, а не список: плитку можно поставить на любую
      ячейку, между занятыми остаются пустые, и дырка не схлопывается. Ячейки нумеруются снизу вверх,
      поэтому новые прирастают сверху.
  - Test: `src/Common/UnitTests/OperationGridTests.swift::testCellsKeepGapsBetweenOccupiedSlots`
  - Evidence: `./run check`
- [x] FR-UX.TILE-ARRANGE: в режиме правки каждая пустая ячейка показывает «+ Добавить», и операция
      встаёт именно в нажатую ячейку, а не в конец списка.
  - Test: `src/MainApp/UITests/OperationEditingUITests.swift::testEditModeShowsAddButtonOnEmptyCells`
  - Evidence: `tuist test UITests --configuration Debug`
- [x] FR-UX.TILE-ARRANGE: и приподнятая, и едущая под пальцем плитка выглядят как сама плитка — без
      белого прямоугольника вокруг и без кнопки удаления.
  - Test: `src/Common/UnitTests/OperationGridLayoutTests.swift::testCellWidthFillsTheScreenWithGapAndPaddings`
  - Evidence: manual — korchasa, снимки экрана на обоих этапах переноса. Синтетические касания через
    `simctl` drag-сессию UIKit не поднимают; поднять её удалось разовым XCUITest-прогоном с
    `press(forDuration:thenDragTo:withVelocity:thenHoldForDuration:)` и снятием экрана снаружи
- [x] FR-UX.TILE-ARRANGE: удержание плитки включает режим правки, не дожидаясь кнопки «Edit», и само
      по себе не открывает форму правки.
  - Test: `src/MainApp/UITests/OperationEditingUITests.swift::testLongPressOnTileTurnsOnEditMode`
  - Evidence: `tuist test UITests --configuration Debug`
- [x] FR-UX.OPERATION-TILES: на главном экране плитки прижаты к нижнему краю — свободное место
      уходит наверх, чтобы до плиток доставал большой палец одной руки; когда плиток больше, чем
      помещается на экран, список прокручивается как обычно.
  - Test: manual — korchasa
  - Evidence: запуск на симуляторе iPhone 17, снимок главного экрана
- [x] FR-UX.SHARE-INPUT-PREVIEW: экран выбора показывает сверху текст или ссылку, которую собирается
      обработать, с подписью, различающей текст и ссылку; длинный вход обрезается.
  - Test: `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift::testUpdateInputText_PublishesPreviewAndDetectsURL`
  - Evidence: `./run check`
- [x] FR-UX.OPERATION-TILES, FR-UX.TILE-ARRANGE, FR-UX.SHARE-INPUT-PREVIEW: три раздела SRS переведены
      в `**Status:** [x]`, когда работа сдана; разделы и строки индекса уже заведены этим планом.
  - Test: manual — korchasa
  - Evidence: `grep -c 'ANC:fr:ux.operation-tiles\|ANC:fr:ux.tile-arrange\|ANC:fr:ux.share-input-preview' documents/srs.md`

## Solution

Выбран вариант B: плитка держится устойчивым `UUID`, а не позицией в массиве.

### 1. Устойчивый идентификатор операции и миграция хранилища

`src/Common/Sources/Models/InventoryOperation.swift`:

- Добавить `public let id: UUID`; в инициализаторе — параметр `id: UUID = UUID()`, чтобы существующие
  вызовы не ломались.
- Написать `init(from decoder:)` вручную: `id` декодируется как `UUID?`, отсутствие означает
  «сгенерировать новый», а не «отбросить запись». Остальные поля — как раньше. Кодирование остаётся
  синтезированным.
- `hash(into:)` считает только `id` — он уникален по построению.
- `Equatable` остаётся синтезированным, то есть в сравнение добавляется и `id`. Это осознанное
  решение: две одинаково настроенные, но разные операции теперь не равны, и `Hashable` перестаёт
  противоречить `Equatable`. Существующие проверки в `HomeViewModelTests.swift:36,77,102,129`
  сравнивают те же самые объекты, которые сами и создали, поэтому остаются зелёными.
- `with(customPrompt:)` переносит прежний `id`: правка промпта не должна создавать новую операцию.
- Добавить `with(id: UUID)` — копию с подменённым идентификатором.

`src/Common/Sources/Models/InventoryOperationDecodingContext.swift` (новый файл): финальный класс с
единственным изменяемым флагом `didGenerateIdentifier`. Кладётся в `JSONDecoder.userInfo` под своим
`CodingUserInfoKey`; `init(from:)` поднимает флаг, когда поля `id` в JSON не было. Это единственный
надёжный способ отличить «старая запись» от «новая», не разбирая JSON руками.

`src/Common/Sources/Models/InventoryManager.swift`: в `loadInventory()` создавать декодер с этим
контекстом; если после разбора флаг поднят — один раз вызвать `saveInventory(decoded)`. Так старые
операции получают идентификаторы ровно один раз, а не при каждом запуске.

Два ограничения, без которых миграция ломается:

- `init(from:)` обязан работать и без контекста в `userInfo`. `InventoryManager` компилируется в оба
  таргета, но декодируют `InventoryOperation` и другие места — `CustomPromptTests.swift:32`,
  `OperationModelsTests.swift:32,45` берут голый `JSONDecoder()`. Отсутствие контекста означает
  «просто сгенерируй `id` и не сообщай никому», а не отказ разбора.
- Обратную запись делает только приложение. Приложение и расширение работают с одним хранилищем в
  App Group; если оба увидят старый JSON и оба сгенерируют идентификаторы, они запишут друг поверх
  друга разные `UUID`, и порядок плиток разъедется. Поэтому `InventoryManager` получает флаг
  `migratesIdentifiers` (по умолчанию `false`), и `true` ставится только в точке сборки MainApp.
  Расширение читает старые записи, раздаёт им временные идентификаторы в памяти и ничего не пишет.

`src/MainApp/Sources/EditOperationViewModel.swift`: `makeOperation()` сегодня возвращает
`operation.makeInventoryOperation(input:colorHex:)?.with(customPrompt:)`, то есть фабрика собирает
новый объект и приносит с собой свежий `UUID`. Поэтому в конец цепочки добавляется
`.with(id: originalOperation.id)` — идентификатор исходной операции возвращается на место.
Протокол `OperationType.makeInventoryOperation` при этом не меняется: иначе пришлось бы править пять
его реализаций, пять вызовов в `InventoryManager.fillWithDefaultOperationsIfNeeded` и десять вызовов
в тестах расширения — ради значения, которое всё равно перезаписывается строкой ниже.

### 2. Чистая перестановка

`src/Common/Sources/Models/OperationReorder.swift` (новый файл): `OperationReorder.move(_:from:to:)`
принимает массив операций и два индекса, возвращает новый массив. Никакого UI и никакого хранилища —
вся логика «куда встанет плитка» проверяется юнит-тестом, включая случай двух одинаково настроенных
операций (теперь они различимы по `id`).

`HomeViewModel.reorderOperations(fromOffsets:toOffset:)` начинает использовать эту функцию; сигнатура
не меняется, существующие тесты остаются в силе.

### 3. Плитка в режиме правки

`src/Common/Sources/OperationTileConstants.swift`: добавить размер бейджа, его смещение относительно
угла плитки, амплитуду и период дрожания. Геометрия покоя не меняется — расширение продолжает рисовать
ту же плитку.

`src/Common/Sources/OperationTileWiggle.swift` (новый файл): `OperationTileWiggle` с чистой функцией
`amplitude(isEditing:reduceMotion:)`, возвращающей ноль, когда включено «Уменьшение движения» или
режим правки выключен. Функция живёт в Common, чтобы её можно было проверить юнит-тестом без UI.

`src/MainApp/Sources/Components/OperationTileButton.swift` (новый файл): кнопка вокруг
`OperationTileView`. В покое — тап открывает лист правки, `accessibilityIdentifier` остаётся
`operation_row_<kind>` (на него завязаны три UI-теста). В режиме правки — кнопка выключается, плитка
качается через `rotationEffect` с фазой от `operation.id.hashValue`, чтобы соседние плитки не
качались в такт, и получает overlay-бейдж с минусом в левом верхнем углу: системный красный,
`accessibilityLabel` — существующий ключ `home_delete`.

`src/MainApp/Sources/Components/OperationDropDelegate.swift` (новый файл): `DropDelegate`, который на
`dropEntered` двигает плитку в локальном состоянии представления, а в хранилище пишет один раз — на
`performDrop`. Тело каждого замыкания держим короче 30 строк ради SwiftLint.

### 4. Главный экран

`src/MainApp/Sources/HomeView.swift`:

- Удалить мёртвый `private struct OperationRowView` целиком.
- Сетка: `ScrollView` + `LazyVGrid(columns: OperationGridLayout.columns)`, `ForEach` не по операциям,
  а по ячейкам из `OperationGrid.displayOrder` — модель хранит номер ячейки, поэтому дырки между
  плитками сохраняются. Нумерация идёт снизу вверх: нулевая ячейка стоит в левом нижнем углу, и новые
  ряды прирастают сверху, ближе к свободной руке.
- В режиме правки к сетке добавляется ещё один пустой ряд, а каждая пустая ячейка рисуется как
  `OperationAddCellButton` — пунктирная рамка с «+ Добавить». Нажатие запоминает номер ячейки в
  `addTargetSlot`, и созданная операция встаёт именно туда.
- Ширину ячейки сетка считает от контейнера (`GeometryReader`), а не от `UIScreen`, и передаёт плиткам:
  на iPad окно приложения бывает уже экрана, и превью перетаскивания вылезало бы за плитку.
- Перетаскивание живёт внутри `OperationTileButton`, а не в `HomeView`: `HomeView` только передаёт
  груз через `dragItem`. Это не косметика — от того, на каком представлении висит `.onDrag`, зависит
  картинка на экране. Перенос идёт двумя этапами, и они берут разные картинки: при «приподнятии»
  система снимает сам источник переноса как есть, а поехавшая плитка рисуется из замыкания
  `preview:`. Пока `.onDrag` висел на `ZStack` вместе с бейджем, снимок приподнятой плитки захватывал
  вынесенный за угол минус, а вокруг шёл непрозрачный прямоугольник по границам снимка. Поэтому
  `.onDrag` висит на самой кнопке-плитке, а бейдж остаётся её соседом по `ZStack` снаружи.
- Форму подложки под обе картинки задаёт
  `contentShape(.dragPreview, RoundedRectangle(cornerRadius: OperationTileConstants.cornerRadius))`:
  по умолчанию система подкладывает прямоугольник, и он торчит из-под скруглённых углов плитки.
- Приёмник — `OperationDropDelegate` на каждой ячейке, он зовёт `HomeViewModel.placeOperation(id:at:)`.
- Вне режима правки на той же кнопке-плитке висит удержание, включающее правку, — как на домашнем
  экране iOS. Жест обязан быть `simultaneousGesture(LongPressGesture(…))`: собственный жест `Button`
  забирает нажатие себе, и обычный `onLongPressGesture` поверх кнопки не срабатывает вовсе. Отпускание
  пальца после удержания форму правки не открывает — к этому моменту режим уже активен, а действие
  кнопки в нём ничего не делает.
- Кнопка Edit в шапке переключает `editMode`. Привязка `\.environment(\.editMode, $editMode)` должна
  стоять ВНУТРИ `NavigationStack`: снаружи стек подсовывает содержимому собственный `editMode`, и
  кнопка переключает его, а не наш — плитки об этом не узнают.
- Сетка прижата к нижнему краю: `GeometryReader` + `ScrollView`, внутри `VStack` со `Spacer(minLength: 0)`
  перед сеткой и `.frame(minHeight: высота экрана, alignment: .bottom)`. Свободное место уходит вверх,
  а когда плиток больше, чем помещается, список прокручивается как обычно.
- Плитка в режиме правки не выключается через `.disabled`: выключенная кнопка бледнеет, а плитка
  должна оставаться яркой, как иконка приложения. Вместо этого действие само проверяет режим.
- Нажатие на минус ставит операцию в `@State private var pendingDeletion` и показывает
  `.alert` с текстом `home_delete_confirm`, деструктивной кнопкой `home_delete` и отменой
  `edit_operation_cancel`. Удаление вызывается только после согласия.
- Убрать из `init` строки `_ = L10n.homeSortHint` и `_ = L10n.homeSortHandle`: `homeSortHint`
  вешается на плитку как `accessibilityHint`, `homeSortHandle` — как `accessibilityLabel` области
  захвата. Обходной приём для Periphery для этих двух ключей уходит.
- `homeOrder` заголовком режима правки не становится: такого заголовка на макете нет и пользователь
  его не просил. Строка `_ = L10n.homeOrder` в `init` остаётся, пока ключ не удалён из ресурсов;
  вычистить его — в Follow-ups.

`src/MainApp/Sources/CraftifyApp.swift`: точка сборки приложения ставит `migratesIdentifiers: true`
и понимает аргумент запуска `-CraftifyResetInventory`, которым UI-тесты сбрасывают список операций.

`src/ShareExtension/Sources/ShareExtensionView.swift`: заменить `ForEach(viewModel.operations, id: \.id)`
на `ForEach(viewModel.operations)` — модель уже `Identifiable` с устойчивым `id`.

### 5. Локализация

Новых ключей не нужно: подпись бейджа — `home_delete`, текст подтверждения — `home_delete_confirm`,
отмена — `edit_operation_cancel`, подсказки перетаскивания — `homeSortHint` и `homeSortHandle`
(имена в `.strings` записаны именно так, camelCase, см. `en.lproj/Localizable.strings:14-15`).
Все пять уже есть во всех 11 локалях MainApp. Ключи расширения
(`share_input_caption`, `share_input_caption_link`, `sentence_count_*`) добавлены ранее в этой же
работе; паритет проверяет `./run check`.

### 6. Тесты

- `src/Common/UnitTests/OperationGridTests.swift` (новый) — вся модель ячеек: дырки не схлопываются,
  плитка встаёт на пустую ячейку, занятую меняет местами со своей, порядок вывода идёт снизу вверх.
- `src/Common/UnitTests/OperationGridLayoutTests.swift` (новый) — ширина ячейки: две колонки с
  промежутком и отступами дают ровно ширину экрана. На ней держится превью перетаскивания.
- `src/Common/UnitTests/InventoryOperationMigrationTests.swift` (новый) — JSON без `id` декодируется,
  получает идентификаторы, флаг миграции поднимается один раз, повторная загрузка идентификаторы не
  меняет.
- `src/Common/UnitTests/OperationTileWiggleTests.swift` (новый) — амплитуда нулевая при «Уменьшении
  движения» и вне режима правки. Тест проверяет только чистую функцию; то, что представление
  действительно читает `@Environment(\.accessibilityReduceMotion)` и передаёт значение внутрь,
  остаётся на ручной проверке — юнит-теста на это в проекте нет и заводить UI-тест ради системной
  настройки доступности несоразмерно.
- `src/MainApp/UnitTests/InventoryOperationIdentityTests.swift` (новый) — идентификатор переживает
  правку и перестановку: операция правится через `EditOperationViewModel`, переставляется через
  `OperationGrid.place`, `id` до и после совпадает. Это и есть проверка того, ради чего выбран
  вариант B. Файл лежит в `MainApp`, а не в `Common`: `CommonUnitTests` не видит
  `EditOperationViewModel`.
- `OperationDropDelegate` юнит-тестом не покрывается: `DropDelegate` — протокол UIKit-слоя, вся его
  логика сводится к вызову `OperationGrid.place`, который проверен отдельно. Само перетаскивание
  проверяется ручным прогоном: синтетические касания через `simctl` drag-сессию UIKit не поднимают,
  поэтому UI-тестом это не берётся.
- `src/Common/UnitTests/OperationDisplayTests.swift` (уже написан) — паритет подписей.
- UI-тесты стартуют с аргументом `-CraftifyResetInventory`: `CraftifyApp.init` видит его и сбрасывает
  список операций к дефолтному. Без сброса тест, который удаляет плитку, оставлял бы её удалённой в
  хранилище App Group и ронял соседние тесты на следующих прогонах. Аргумент читается через
  `ProcessInfo`, а не через `UserDefaults`, чтобы не связываться с разбором домена аргументов.
- Тесты, которые ищут системные кнопки по надписи («Edit», «Cancel», «Delete»), стартуют ещё и с
  `-AppleLanguages (en) -AppleLocale en_US`. Иначе они падают на симуляторе с русской системой:
  кнопка называется «Править», и запрос по идентификатору её не находит.
  `SettingsModelPickerUITests` вместо этого ищет саму панель навигации, а не её локализованный
  заголовок — там язык по умолчанию проверяется намеренно.
- `src/MainApp/UITests/OperationEditingUITests.swift` — `testSwipeRevealsDeleteOnListRow` заменяется
  на `testEditModeShowsDeleteBadgeAndRemovesTile` и
  `testDeleteBadgeAsksConfirmationBeforeRemoving`: свайпа по строке больше нет, удаление живёт на
  минусе в режиме правки. `testColorPickerPopoverOpensAndSelects` и `EditOperationPromptUITests`
  продолжают работать — идентификатор `operation_row_<kind>` сохранён на плитке.
- `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift` (уже написан) — шапка с входным
  текстом.

### 7. Проверка

- `./run check` — весь шлюз: gitleaks, генерация, формат, строгий линт, Periphery, паритет локализаций,
  сборка и тесты, скан комментариев. Важно: `check` запускает `tuist test AllTests`, а в этот план
  входят только `MainAppUnitTests`, `ShareExtensionUnitTests` и `CommonUnitTests`
  (`Project.swift:252`). UI-тесты живут в отдельной схеме (`Project.swift:259-263`), и `./run check`
  их не гоняет.
- `tuist test UITests --configuration Debug` — отдельный прогон UI-тестов; без него два пункта
  Definition of Done остаются непроверенными.
- Ручная проверка на симуляторе: главный экран — Edit включает дрожание и минусы, плитка
  перетаскивается, порядок держится после перезапуска; поделиться текстом и ссылкой из Safari — шапка
  показывает нужную подпись, плитки стоят в том же порядке, что и в приложении.
- UI-тесты, меняющие ориентацию, оставляют симулятор в ней между прогонами: если портретный тест
  падает с «not hittable», перезагрузить симулятор (`simctl shutdown` + `boot`).

## Follow-ups

- Ячейка под пальцем подсвечивается только когда она пустая: `highlightedSlot` читает лишь
  `OperationAddCellButton`, а занятая плитка на наведение никак не отвечает. Обмен местами происходит
  вслепую — пользователь не видит, с кем поменяется. Решить отдельно: подсвечивать и занятую ячейку.
- Плавность процесса редактирования замерена и признана достаточной — решено оставить как есть.
  Мерил счётчиком кадров на `CADisplayLink` внутри приложения плюс UI-тестом, проходящим весь процесс:
  вход в правку удержанием, перетаскивание плитки на пустую ячейку, выход и повторный вход кнопкой.
  Собственный код дёшев: переключение режима 0 мс, `placeOperation` 1–4 мс, а все вычисления одного
  «кадра» сетки из десяти плиток укладываются в 110 мкс при бюджете 16.7 мс. Единственная устойчивая
  просадка — вход в режим правки, 66–88 мс, то есть 3–5 кадров; повторяется в Debug и Release и не
  зависит от анимации перехода (проверено отдельным прогоном без `withAnimation`). Причина: у ячейки
  меняется не значение, а набор модификаторов (в правке появляются приём перетаскивания и
  прозрачность, уходит удержание), а ветки `if/else` для SwiftUI — разные представления, поэтому
  поддерево строится заново, а не обновляется. Убрать просадку можно, сделав набор модификаторов
  постоянным, но однократный щелчок при переключении того не стоит. Остальные просадки в 1–3 кадра
  между прогонами скакали от 12 до 39 штук при неизменном коде — это фон машины, а не приложение.
  Все замеры сняты на симуляторе, где рендеринг идёт через GPU хоста; окончательная проверка
  плавности — Instruments на устройстве.

- В ручной проверке шторка расширения заняла почти весь экран, хотя контента там на треть. Я не успел
  сравнить с состоянием до правок, поэтому не знаю, регрессия это или давняя болячка
  `ShareExtensionViewController.updatePresentationHeight`. Проверить отдельно, вне этой задачи.
- Ключ `home_order` остаётся неиспользованным во всех 11 локалях MainApp — его держит только строка
  `_ = L10n.homeOrder` в `HomeView.init`. Решить отдельно: удалить ключ из ресурсов или найти ему
  применение.
- Правка настройки прямо в плитке (пикер без открытия листа) не делается: тап по-прежнему открывает
  форму правки.
- Кнопки «Править» и «Настройки» с макета 11b на экране расширения не появляются — там остаётся одна
  «Закрыть». Нужно ли расширению уводить в приложение — отдельное решение.
- Португальские подписи длины резюме в MainApp были не переведены («sentences»); поправлено заодно,
  потому что иначе два экрана в pt показывали бы разное.
