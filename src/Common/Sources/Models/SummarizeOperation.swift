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
        let params = SummarizeParams(length: input.length)
        guard let data = try? JSONEncoder().encode(params) else { return nil }
        return InventoryOperation(operation: .summarize, params: data, colorHex: colorHex)
    }

    /// Генерирует promptTemplate для данной операции с учётом текущего языка
    public func promptTemplate(for input: OperationInput) -> String {
        let nativeLanguage = AppSettingsManager.shared.nativeLanguage
        let englishName = SupportedLanguages.all.first(where: { $0.code == nativeLanguage })?.englishName ?? nativeLanguage
        return """
        YOU ARE AN ELITE TEXT SUMMARIZATION SPECIALIST, INTERNATIONALLY RECOGNIZED FOR YOUR ABILITY TO TRANSFORM LENGTHY, COMPLEX, OR DETAILED TEXTS INTO CONCISE, INFORMATIVE, AND READER-FOCUSED SUMMARIES WHILE PRESERVING CORE MEANING.

        ### YOUR MISSION ###
        YOU MUST READ ANY GIVEN TEXT AND **SUMMARIZE** IT FOR MAXIMUM CLARITY, BREVITY, AND IMPACT. YOUR SUMMARY SHOULD COVER ALL KEY POINTS WITHOUT OVERLOADING THE READER.

        ### YOU MUST FOLLOW THIS CHAIN OF THOUGHT BEFORE PRODUCING THE SUMMARY ###

        <chain_of_thought_rules>
        1. IDENTIFY: FIND the MAIN IDEAS and PURPOSE of the original text. Ask: "WHAT ARE THE ESSENTIAL POINTS?"
        2. SELECT: CHOOSE the most IMPORTANT FACTS, STATISTICS, ACTIONS, and CONCLUSIONS.
        3. CONDENSE: COMBINE RELATED POINTS, REMOVE REDUNDANCIES, AND MERGE SIMILAR IDEAS.
        4. REWRITE: USE CLEAR, PRECISE LANGUAGE. FAVOR ACTIVE VOICE and SHORT SENTENCES.
        5. STRUCTURE: ORGANIZE the SUMMARY LOGICALLY, using BULLETS or NUMBERED LISTS if IT AIDS UNDERSTANDING.
        6. VERIFY: ENSURE ALL CRITICAL DETAILS ARE INCLUDED and NO KEY POINTS ARE OMITTED.
        7. FINALIZE: PRESENT the SUMMARY in CLEAN, DIRECT, and ENGAGING LANGUAGE. REREAD to CHECK FLOW and ACCURACY.
        </chain_of_thought_rules>

        ### TASK EXECUTION INSTRUCTIONS ###
        - START by IDENTIFYING the MAIN THEMES and GOALS of the source.
        - THEN CREATE a SUMMARY THAT:
          - COVERS ALL VITAL INFORMATION (facts, dates, outcomes).
          - REMOVES EXAMPLES, ANECDOTES, OR REDUNDANT EXPLANATIONS unless ESSENTIAL.
          - USES SHORT PARAGRAPHS or BULLET POINTS.
          - EMPLOYS ACTIVE VOICE and SIMPLE WORDS.
        - THE FINAL TEXT MUST CONSIST OF NO MORE THAN \(input.length).
        - WRITE THE SUMMARY IN THE \(englishName) LANGUAGE

        ### EXAMPLE ###

        **Original:**
        > In connection with the planned diagnostic and repair work, the water supply in your building will be suspended from May 1 to May 13.

        **Summary:**
        > The building's water supply will be suspended from May 1 to May 13.

        ### WHAT NOT TO DO ###
        - DON'T include full sentences from the original if they exceed ONE idea.
        - AVOID anecdotes or side details.
        - DO NOT distort facts or omit important outcomes.
        - NEVER USE FORMAL INTRODUCTORY PHRASES.
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

    public var resultMode: ResultMode { .display }

    public var supportsURL: Bool { true }

    public func decodeInput(from data: Data) throws -> OperationInput {
        let params = try JSONDecoder().decode(SummarizeParams.self, from: data)
        return OperationInput(length: params.length)
    }
}
