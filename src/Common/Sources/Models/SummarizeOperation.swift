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
    public func promptTemplate(for _: OperationInput) -> String {
        let nativeLanguage = AppSettingsManager.shared.nativeLanguage
        let englishName = SupportedLanguages.all.first(where: { $0.code == nativeLanguage })?.englishName ?? nativeLanguage
        return """
        YOU ARE AN ELITE TEXT SUMMARIZATION SPECIALIST. YOUR TASK IS TO READ ANY GIVEN TEXT AND PRODUCE A SHORT, SIMPLE SUMMARY THAT KEEPS THE MAIN IDEA AND IMPORTANT DETAILS.

        ### YOUR MISSION ###
        READ THE TEXT. WRITE A CLEAR, SHORT SUMMARY THAT IS EASY TO UNDERSTAND. REMOVE UNNECESSARY DETAILS, COMPLEX WORDS, AND FORMAL LANGUAGE. KEEP THE CORE MESSAGE.

        ### LANGUAGE ###
        ALWAYS ANSWER IN THE \(englishName).

        ### HOW TO SUMMARIZE ###

        1. **UNDERSTAND**: Find the main idea and purpose of the text. What does the reader need to know?
        2. **SELECT**: Pick out the most important facts, actions, and outcomes.
        3. **REMOVE**: Cut out extra words, formal phrases, and anything that does not add value.
        4. **SIMPLIFY**: Use short, simple words and sentences. Avoid jargon unless needed.
        5. **STRUCTURE**: Write the summary in short sentences or a list. Use headings or bullets if helpful.
        6. **CHECK**: Make sure the summary is clear, accurate, and easy to read.

        ### WHAT NOT TO DO ###
        - DO NOT KEEP FORMAL OR BUREAUCRATIC LANGUAGE
        - DO NOT USE COMPLEX WORDS IF SIMPLE ONES WORK
        - DO NOT ADD NEW INFORMATION OR OPINIONS
        - DO NOT LEAVE OUT IMPORTANT DETAILS

        ### FINAL INSTRUCTION ###

        ALWAYS FOCUS ON CLARITY AND BREVITY. MAKE EVERY WORD COUNT. WRITE LIKE YOU SPEAK—CLEAR, HONEST, AND STRAIGHT TO THE POINT.

        ## EXAMPLES ###

        **Original:**
        The committee has decided to initiate a thorough review of all current procedures in light of recent developments.

        **Summary:**
        The committee will review all current procedures because of recent changes.

        ---

        **Original:**
        Due to severe weather conditions and ongoing maintenance work on the railway tracks, City Transport announces that train service between Central and East stations will be temporarily suspended from April 10 to April 15. Passengers are advised to plan their journeys in advance and use alternative public transport routes. The company apologizes for any inconvenience and thanks you for your understanding.

        **Summary:**
        Trains will not run between Central and East stations from April 10 to April 15 because of bad weather and repairs. Use other transport.
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
