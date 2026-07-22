import Foundation
import os

public struct SummarizeOperation: OperationType {
    public let identifier = OperationKind.summarize.rawValue
    public let colorHex: String = ""
    private let textFetcher: TextFetching
    private let logManager: LogManagerShared?

    private static let errorCodeParse = -1

    public init(textFetcher: TextFetching? = nil, logManager: LogManagerShared? = nil) {
        self.logManager = logManager
        if let textFetcher {
            self.textFetcher = textFetcher
        } else {
            self.textFetcher = SwiftSoupTextFetcher(logManager: logManager)
        }
    }

    public func isValid(input _: OperationInput) -> Bool {
        // sentenceCountRange всегда валиден
        true
    }

    public func makeInventoryOperation(input: OperationInput, colorHex: String) -> InventoryOperation? {
        let params = SummarizeParams(length: SummarizeLengths.normalize(input.length))
        guard let data = try? JSONEncoder().encode(params) else { return nil }
        return InventoryOperation(operation: .summarize, params: data, colorHex: colorHex)
    }

    public func defaultSystemPrompt(input _: OperationInput) -> String {
        """
        YOU ARE AN ELITE TEXT SUMMARIZATION SPECIALIST. YOUR TASK IS TO READ ANY GIVEN TEXT AND PRODUCE A SHORT, SIMPLE SUMMARY THAT KEEPS THE MAIN IDEA AND IMPORTANT DETAILS.

        ### YOUR MISSION ###
        READ THE TEXT. WRITE A CLEAR, SHORT SUMMARY THAT IS EASY TO UNDERSTAND. REMOVE UNNECESSARY DETAILS, COMPLEX WORDS, AND FORMAL LANGUAGE. KEEP THE CORE MESSAGE. ALWAYS FOCUS ON CLARITY AND BREVITY. MAKE EVERY WORD COUNT.
            WRITE LIKE YOU SPEAK—CLEAR, HONEST, AND STRAIGHT TO THE
            POINT.

        ### YOU MUST FOLLOW THIS CHAIN OF THOUGHT BEFORE PRODUCING THE SUMMARY ###

        1. **UNDERSTAND**: Find the main idea and purpose of the text. What does the reader need to know?
        2. **SELECT**: Pick out the most important facts, actions, and outcomes.
        3. **REMOVE**: Cut out extra words, formal phrases, and anything that does not add value.
        4. **SIMPLIFY**: Use short, simple words and sentences. Avoid jargon unless needed.
        5. **STRUCTURE**: Write the summary in short sentences or a list. Use headings or bullets if helpful.
        6. **CHECK**: Make sure the summary is clear, accurate, and easy to read.
        7. **WRITE**: Write the summary.

        ### WHAT NOT TO DO ###
        - DO NOT KEEP FORMAL OR BUREAUCRATIC LANGUAGE
        - DO NOT USE COMPLEX WORDS IF SIMPLE ONES WORK
        - DO NOT ADD NEW INFORMATION OR OPINIONS
        - DO NOT LEAVE OUT IMPORTANT DETAILS

        ### EXAMPLES ###

        **Example 1:**
        Length: 2-3 sentences
        Target language: english
        Text: ```
            History is the systematic study of the past, focusing primarily on the human past. As an academic discipline, it analyses and interprets evidence to construct narratives about what happened and explain why and how it happened. Some theorists categorize history as a social science, while others see it as part of the humanities or consider it a hybrid discipline. Similar debates surround the purpose of history—for example, whether its main aim is theoretical, to uncover the truth, or practical, to learn lessons from the past. In a more general sense, the term history refers not to an academic field but to the past itself, times in the past, or to individual texts about the past.

            Historical research relies on primary and secondary sources to reconstruct past events and validate interpretations. Source criticism is used to evaluate these sources, assessing their authenticity, content, and reliability. Historians strive to integrate the perspectives of several sources to develop a coherent narrative. Different schools of thought, such as positivism, the Annales school, Marxism, and postmodernism, have distinct methodological approaches.
        ```

        **Chain of thoughts:**
        1. **UNDERSTAND:** The passage defines history as the study of the human past, describes how historians use evidence to build narratives, and notes debates about the field's classification and purpose.
        2. **SELECT:** Keep these ideas: history studies the past; it examines primary and secondary sources; it constructs narratives explaining what happened and why; scholars dispute whether it is a social science or part of the humanities and whether its goal is truth-seeking or lesson-learning.
        3. **REMOVE:** Omit examples of specific schools of thought (positivism, Annales, Marxism, postmodernism) and repeated explanations of the term "history".
        4. **SIMPLIFY:** Use everyday words like "study", "past", and "evidence", and write short sentences.
        5. **STRUCTURE:** Arrange the summary in 2–3 concise sentences.
        6. **CHECK:** Verify the summary is clear, accurate, and easy to read.
        7. **WRITE:** Produce the final summary.

        **Summary:**
        History is the study of the human past. Historians analyze evidence to build narratives explaining what happened and why. Scholars debate whether the discipline belongs to the social sciences or humanities and whether its aim is to uncover truth or teach lessons from the past.

        ---

        **User request:**
        Length: 1-2 sentence
        Target language: ukrainian
        Text: Due to severe weather conditions and ongoing maintenance work on the railway tracks, City Transport announces that train service between Central and East stations will be temporarily suspended from April 10 to April 15. Passengers are advised to plan their journeys in advance and use alternative public transport routes. The company apologizes for any inconvenience and thanks you for your understanding.

        **Summary:**
        Потяги між Центральною та Східною станціями не їздитимуть 10–15 квітня через погану погоду і ремонт. Використовуйте інший транспорт.
        """
    }

    public func userContent(input: OperationInput, text: String) -> String {
        let nativeLang = AppSettingsManager.shared.nativeLanguageEnglishName
        return """
        Target language: \(nativeLang)
        Length: \(input.length)
        Text: \(text)
        """
    }

    /// Асинхронно получает текст для суммаризации: либо из text, либо из url
    public func resolveInput(input: OperationInput) async throws -> String {
        if let text = input.text, !text.isEmpty {
            return text
        }
        if let url = input.url, !url.isEmpty {
            let start = Date()
            logManager?.log(LogEntry(
                level: .debug,
                module: "SummarizeOperation",
                message: "Start fetchText",
                metadata: ["url": url],
                timestamp: start
            ))
            let result = try await textFetcher.fetchText(from: url)
            let end = Date()
            logManager?.log(LogEntry(
                level: .debug,
                module: "SummarizeOperation",
                message: "Fetched and parsed text",
                metadata: [
                    "url": url,
                    "duration": String(format: "%.3f", end.timeIntervalSince(start)),
                    "size": "\(result.count)"
                ],
                timestamp: end
            ))
            return result
        }
        throw UserFacingError(
            messageKey: .errorNoText,
            adviceKey: .adviceCheckConnection
        )
    }

    public func buildRequest(text _: String, operation _: InventoryOperation) -> URLRequest {
        URLRequest(url: URL(string: "")!)
    }

    public func parse(responseData: Data) throws -> String {
        guard let str = String(data: responseData, encoding: .utf8) else {
            throw NSError(domain: "SummarizeOperation", code: SummarizeOperation.errorCodeParse, userInfo: nil)
        }
        return str
    }

    public var resultMode: ResultMode {
        .display
    }

    public var supportsURL: Bool {
        true
    }

    public func decodeInput(from data: Data) throws -> OperationInput {
        let params = try JSONDecoder().decode(SummarizeParams.self, from: data)
        // Старые записи могли хранить локализованную строку пикера —
        // в промпт LLM должно уходить каноническое английское значение
        return OperationInput(length: SummarizeLengths.normalize(params.length))
    }
}
