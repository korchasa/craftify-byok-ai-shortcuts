import Foundation

public struct SummarizeOperation: OperationType {
    public let identifier = OperationKind.summarize.rawValue
    public let colorHex: String = ""
    private let textFetcher: TextFetching
    private let logManager: LogManagerShared?

    private static let errorCodeNoTextOrURL = -2
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
        let params = SummarizeParams(sentenceCountRange: input.sentenceCountRange)
        guard let data = try? JSONEncoder().encode(params) else { return nil }
        let englishName = SupportedLanguages.all.first(where: { $0.code == input.nativeLanguage })?.englishName ?? input.nativeLanguage
        let prompt = """
        I want you to act as an expert summarizer.

        <instructions>
        - Read user message
        - Summarize the text in exactly \(input.sentenceCountRange.min)-\(input.sentenceCountRange.max) sentences
        - Preserve the main ideas and key details
        - Ignore all information about the cookies
        - Return ONLY the summary text, without any additional formatting
        - Translate the summary to the \(englishName) language
        </instructions>
        """
        return InventoryOperation(operation: .summarize, params: data, promptTemplate: prompt, colorHex: colorHex)
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
        throw NSError(domain: "SummarizeOperation", code: SummarizeOperation.errorCodeNoTextOrURL, userInfo: [NSLocalizedDescriptionKey: "No text or URL provided"])
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
}
