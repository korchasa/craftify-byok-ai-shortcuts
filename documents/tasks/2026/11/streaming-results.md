---
date: 2026-11-17
status: done
implements:
  - FR-UX.STREAMING
related_tasks:
  - "[find-errors-operation](find-errors-operation.md)"
---
# Stream results for Explain, Summarize and Simplify [ANC:task:2026-11-streaming-results]

## Goal

Cut the time a user stares at an empty progress sheet: show the answer as the model writes it (GitHub issue #2).

## Overview

### Context

- Issue #2 asks for streamed results for Explain, Summarize and Simplify.
- The owner chose (2026-11-17): all four providers in one release, and Simplify shows its result on screen while it arrives and copies the finished text to the clipboard.

### Current State

- `LLMClienting.send` returns the whole answer; each of the four clients (`OpenAIAPIClient`, `ClaudeAPIClient`, `MistralAPIClient`, `OpenRouterAPIClient`) builds its own request and parses one JSON body.
- `ProcessingManager` calls `send`, `ShareExtensionManager` stores `lastResult`, and `ShareExtensionViewModel` sets `displayResult` only after completion; a 30-second timer races the whole run.
- `ResultMode` has `.clipboard` (Translate, Correct, Simplify) and `.display` (Explain, Summarize, Find errors).

### Constraints

- OpenAI, Mistral and OpenRouter stream the OpenAI chat format: `data: {"choices":[{"delta":{"content":…}}]}` lines ending with `data: [DONE]`; OpenRouter also sends `: comment` keep-alive lines and may put an `{"error":…}` object in a data line.
- Claude streams typed events: text arrives in `content_block_delta` events with `delta.type == "text_delta"`; an `error` event carries the error; `message_stop` ends the stream.
- Find errors needs the whole JSON answer, so it is not streamed.
- The seven `ProcessingManaging` test stubs must keep compiling.

## Definition of Done

- [x] FR-UX.STREAMING: OpenAI-format chunks are joined until `[DONE]`
  - Test: `src/ShareExtension/UnitTests/LLMStreamParsingTests.swift::testOpenAIChunksYieldTextUntilDone`
  - Evidence: `deno task test ShareExtensionUnitTests/LLMStreamParsingTests`
- [x] FR-UX.STREAMING: Claude text deltas are joined until `message_stop`
  - Test: `src/ShareExtension/UnitTests/LLMStreamParsingTests.swift::testClaudeDeltasYieldTextUntilStop`
  - Evidence: `deno task test ShareExtensionUnitTests/LLMStreamParsingTests`
- [x] FR-UX.STREAMING: an error inside the stream is thrown as a provider error
  - Test: `src/ShareExtension/UnitTests/LLMStreamParsingTests.swift::testErrorInsideTheStreamIsThrown`
  - Evidence: `deno task test ShareExtensionUnitTests/LLMStreamParsingTests`
- [x] FR-UX.STREAMING: the clients send a streaming request and join the pieces; an HTTP error is mapped as before
  - Test: `src/ShareExtension/UnitTests/LLMStreamingIntegrationTests.swift::test_openAI_stream_sendsStreamFlagAndJoinsChunks`, `::test_claude_stream_joinsTextDeltas`, `::test_stream_httpError_isMapped`
  - Evidence: `deno task test ShareExtensionUnitTests/LLMStreamingIntegrationTests`
- [x] FR-UX.STREAMING: the result screen shows text before the run completes, and the timeout does not cut a streaming answer
  - Test: `src/ShareExtension/UnitTests/ShareExtensionViewModelTests.swift::testProcess_StreamedTextIsShownBeforeCompletion`, `::testProcess_TimeoutDoesNotCutAStreamingAnswer`
  - Evidence: `deno task test ShareExtensionUnitTests/ShareExtensionViewModelTests`
- [x] FR-UX.STREAMING: Simplify shows its result and copies it to the clipboard
  - Test: `src/ShareExtension/UnitTests/ShareExtensionManagerTests.swift::testSimplifyShowsResultAndCopiesIt`
  - Evidence: `deno task check`

## Solution

1. `LLMClienting.stream(messages:apiKey:) -> AsyncThrowingStream<String, Error>` yielding text pieces; a protocol-extension default wraps `send` in one piece (for test doubles).
2. `LLMStreamParsing` (pure functions): `openAIChatPiece(data:model:)` and `claudePiece(event:data:model:)` return `.text`, `.done` or `.skip`, or throw the mapped provider error.
3. `LLMEventStream.run(request:session:model:parse:)`: `URLSession.bytes(for:)`; a non-200 status reads the body and throws `LLMHTTPErrorMapper.error`; otherwise it walks `event:`/`data:` lines through the parser. Connection errors before the first piece are retried with the clients' delays; cancellation becomes `LLMAPIClientError.cancelled`.
4. Each client extracts `makeRequest(messages:apiKey:stream:)` from `send` and implements `stream` with it (`"stream": true` in the body).
5. `OperationType.streamsResult` (false by default; true for Explain, Summarize, Simplify). `ProcessingManaging` gains `process(text:operation:onPartial:completion:)` with a default that ignores `onPartial`; `ProcessingManager` streams when the operation allows it, calls `onPartial` with the accumulated text at most every 0.1 s, and finishes with the full text.
6. `ShareExtensionManager.process(text:operation:onPartial:)` forwards partials; `ResultMode.displayAndCopy` makes it copy the finished text and return success without closing.
7. `ShareExtensionViewModel`: a partial sets `displayResult` (ignored once the run has completed) and marks the run as streaming; the view hides the progress overlay once text is shown and disables Copy while processing; when the timer fires on a streaming run the view model waits for the work instead of failing.
8. Simplify switches to `.displayAndCopy`; the result screen shows a "copied" note for that mode (new string in 11 locales).
9. Live check against each provider the owner holds a key for; simulator check of the growing text.

## Verification notes

- `deno task check`, 2026-11-17: 268 tests green, SwiftLint strict clean, the app launches in the simulator. Besides the DoD tests, `ProcessingManagerLLMIntegrationTests::test_streamingOperation_reportsGrowingText` and `::test_findErrors_isNotStreamed` cover the processing layer.
- Live OpenAI stream, `gpt-5.6-luna`, 2026-11-17: `text/event-stream`, only `data:` lines, `choices[0].delta.content` pieces and a closing `data: [DONE]` — the shape the parser expects. First text after 2.4 s, whole answer after 3.5 s, 122 pieces.
- Share sheet on the iPhone 17 simulator with the owner's OpenAI key, 2026-11-17, Debug build: Summarize on `https://en.wikipedia.org/wiki/Nocebo`, frames captured with `simctl io screenshot` about every 0.4 s. The first two sentences appeared 3.0 s after the tap, the text grew in place at 3.5 s and 3.9 s, and the answer was whole at 4.3 s. Simplify on the same link showed the answer and the "copied" note.
- The same walk found the answer narrower than the title and the buttons: `MarkdownLLMView` padded all four sides inside a screen that already supplies the side margin. It now pads only top and bottom.
- Not checked live: Claude, Mistral and OpenRouter (no keys in this environment; their formats are covered by recorded-event tests).
