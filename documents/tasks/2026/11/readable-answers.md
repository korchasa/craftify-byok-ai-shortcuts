---
date: 2026-11-18
status: done
implements:
  - FR-OP.READABLE-ANSWERS
related_tasks:
  - "[page-text-forms-charset](page-text-forms-charset.md)"
---
# Summarize and Explain answer in paragraphs, not one block [ANC:task:2026-11-readable-answers]

## Goal

An answer read on the result screen must be easy to scan: a summary of ten sentences or an explanation of several hundred words is unreadable as one block of text.

## Overview

### Context

- The owner saw long answers with no paragraphs or lists on the result screen (2026-11-18).
- The result screen is not the cause: `MarkdownLLMView` parses inline-only and keeps line breaks, so paragraphs the model sends are shown.
- The prompts were. Run on the app's default OpenAI model (`gpt-5.6-luna`) with page text extracted by `PageMainText`, exactly as the app sends it:
  - Summarize at the default tile's length ("9-10 sentences") answered with 10 sentences and no paragraph break, on the OpenNet article and on Wikipedia's Nocebo, in all 4 runs. Its prompt said nothing about layout, banned headings, and both examples were one paragraph.
  - Explain was told to write "a single paragraph of explanation, under 400 words, without lists or headings".
  - Simplify returned a heading and 23 paragraphs on its own and needs no change.

### Current State

- `SummarizeOperation.defaultSystemPrompt`: no layout rule; examples are single paragraphs.
- `ExplainOperation.defaultSystemPrompt`: TL;DR plus one paragraph of up to 400 words.

### Constraints

- Summarize must keep to the chosen length.
- Prompts the user has rewritten are not touched.

## Definition of Done

- [x] FR-OP.READABLE-ANSWERS: Summarize and Explain prompts ask for paragraphs and never for a single paragraph
  - Test: `src/Common/UnitTests/OperationPromptTemplateTests.swift::testOnScreenAnswersAreSplitIntoParagraphs`
  - Evidence: `deno task test CommonUnitTests/OperationPromptTemplateTests`
- [x] FR-OP.READABLE-ANSWERS: at least one example answer in each of the two prompts is split into paragraphs
  - Test: `src/Common/UnitTests/OperationPromptTemplateTests.swift::testOnScreenAnswerExamplesShowParagraphs`
  - Evidence: `deno task check`

## Solution

1. Summarize: one rule that splits the summary into paragraphs of three or four sentences and names the paragraph count for each length; the English example becomes "5-6 sentences" in two paragraphs of three.
2. Explain: the output template asks for two to four short paragraphs under 400 words, with a list only for three or more parallel items; the example's explanation is two paragraphs.

## Verification notes

- RED first: both new tests failed on the old prompts for the reasons they check.
- Wording that failed, kept here so it is not tried again: "short paragraphs of two or three sentences, one topic each" (and the variant "paragraphs only group those sentences and never add to their number") made Summarize overshoot "9-10 sentences" — 12 to 20 sentences in 11 of 12 runs. The old prompt gave exactly 10 in 3 of 3 runs on the same page. Splitting the change showed the rule caused it, not the new example (example alone: 10 sentences, one paragraph, 3 of 3).
- A loose rule was tried too, at the owner's request: "Format the summary so it is easy to read on a phone screen: split it into paragraphs, and use a list … where the text enumerates things." 3 runs per case:
  - "9-10 sentences": 10 to 14 sentences, and the layout changed from run to run — 1 to 7 paragraphs, once every sentence on its own line with no paragraph at all.
  - "18-20 sentences": 17, 24 and 29 sentences, once 19 one-sentence paragraphs.
  - "2-3 sentences": 3 sentences in all 3 runs.
  The paragraph count per length stays: it is what keeps both the length and the layout stable.
- Final wording, 3 runs per case on `gpt-5.6-luna`:
  - "9-10 sentences": 9 sentences in 3 paragraphs in all 6 runs (OpenNet and Nocebo).
  - "2-3 sentences": 3, 4 and 3 sentences; "18-20 sentences": 18, 20 and 20 sentences in 5 or 6 paragraphs.
  - Explain: TL;DR plus 3 paragraphs, 1215–1884 characters, in all 6 runs (the term "Эффект ноцебо" and "Spectre v1 и спекулятивное выполнение").
- `deno task check`: 279 tests passed, 0 failed.
- Not checked: Claude, Mistral and OpenRouter models; the result screen in the simulator.
