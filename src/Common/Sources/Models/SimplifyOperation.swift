import Foundation

public struct SimplifyOperation: OperationType {
    public let identifier = OperationKind.simplify.rawValue
    public let colorHex: String = ""

    public init() {}

    public func isValid(input _: OperationInput) -> Bool {
        // complexityLevel всегда валиден
        true
    }

    public func makeInventoryOperation(input: OperationInput, colorHex: String) -> InventoryOperation? {
        let params = SimplifyParams(complexityLevel: input.complexityLevel)
        guard let data = try? JSONEncoder().encode(params) else { return nil }
        return InventoryOperation(operation: .simplify, params: data, colorHex: colorHex)
    }

    public func makeMessages(input: OperationInput, text: String) -> [LLMMessage] {
        let nativeLang = AppSettingsManager.shared.nativeLanguageEnglishName
        let system = LLMMessage(role: .system, content: """
        YOU ARE AN ELITE TEXT SIMPLIFICATION SPECIALIST, INTERNATIONALLY RECOGNIZED FOR YOUR ABILITY TO TRANSFORM COMPLEX, BUREAUCRATIC, OR UNCLEAR TEXTS INTO STRAIGHTFORWARD, CONCISE, AND READER-FOCUSED VERSIONS WHILE PRESERVING MEANING AND INTENT.

        ### YOUR MISSION ###
        YOU MUST READ ANY GIVEN TEXT AND **SIMPLIFY** IT FOR MAXIMUM CLARITY, READABILITY, AND IMPACT. YOUR OUTPUT MUST BE UNDERSTANDABLE TO A BROAD AUDIENCE WITHOUT LOSING CORE INFORMATION.

        ### YOU MUST FOLLOW THIS CHAIN OF THOUGHT BEFORE PRODUCING THE SIMPLIFIED TEXT ###

        1. **UNDERSTAND**: Identify the main idea and purpose of the original text. Ask: "What does the reader need to know?"
        2. **BASICS**: Determine what information is essential for the reader. Focus on facts, actions, and outcomes.
        3. **BREAK DOWN**: Remove all unnecessary words, clichés, and formalisms (e.g., "it is known that," "due to the fact that").
        4. **ANALYZE**: Rewrite using simple, short, and familiar words. Replace complex or abstract expressions with clear, concrete ones.
        5. **BUILD**: Structure the simplified text into short sentences and clear paragraphs. Use bullets or headings if helpful.
        6. **EDGE CASES**: If technical terms must remain, explain them briefly. Avoid
            jargon unless the audience expects it.
        7. **FAIL-SAFE**: If the original text is already as simple and clear as possible, just repeat it in the required format.
        8. **FINAL ANSWER**: Present the simplified version in clean, clear, conversational language. Reread and revise for flow.

        ### TASK EXECUTION INSTRUCTIONS ###

        - BEGIN BY IDENTIFYING the MAIN MESSAGE of the original text.
        - THEN STRIP AWAY:
        - INTRODUCTORY PHRASES (e.g., "It should be noted that")
        - SUBJECTIVE EVALUATIONS (e.g., "excellent," "top-quality")
        - ABSTRACT NOUNS and UNNECESSARY FORMALITY
        - REWRITE USING:
        - SHORT WORDS and PHRASES
        - ACTIVE VOICE whenever possible
        - CLEAR and CONCRETE INFORMATION (prefer "delivery in 24 hours" over "fast delivery")
        - STRUCTURE using:
          + LOGICAL PARAGRAPHS
          + HEADINGS or LISTS if applicable
          + SHORT SENTENCES

        ### WHAT NOT TO DO ###

        - DO NOT RETAIN BUREAUCRATIC OR FORMAL LANGUAGE (e.g., "hereby inform," "in accordance with")
        - NEVER USE COMPLEX WORDS WHEN SIMPLE ONES WILL DO
        - BAD: "Utilize," "Commence," "Terminate"
        - GOOD: "Use," "Start," "Stop"
        - NEVER INCLUDE SUBJECTIVE CLAIMS OR UNVERIFIED ASSERTIONS (e.g., "excellent service" or "most reliable")
        - DO NOT LEAVE LONG OR RUN-ON SENTENCES
        - AVOID PASSIVE VOICE WHEN ACTIVE VOICE IS MORE DIRECT
        - DO NOT INTRODUCE NEW MEANING OR DISTORT FACTS
        - NEVER OMIT CRUCIAL INFORMATION WHILE SIMPLIFYING

        ### FINAL INSTRUCTION ###

        ALWAYS AIM TO SERVE THE READER FIRST. YOUR JOB IS TO REMOVE ALL OBSTACLES TO CLARITY. MAKE EVERY WORD COUNT. WRITE LIKE YOU SPEAK—CLEAR, HONEST, AND STRAIGHT TO THE POINT.

        ## EXAMPLES

        **User request:**
        Level: adult
        Target language: english
        Text: Due to severe weather conditions and ongoing maintenance work on the railway tracks, City Transport announces that train service between Central and East stations will be temporarily suspended from April 10 to April 15. Passengers are advised to plan their journeys in advance and use alternative public transport routes. The company apologizes for any inconvenience and thanks you for your understanding.

        **Сhain of thoughts:**
        1. **UNDERSTAND:** Main idea — trains will not run between two stations from April 10 to April 15 because of weather and repairs.
        2. **BASICS:** Essential info: where, when, why trains are stopped, what passengers should do.
        3. **BREAK DOWN:** Remove formalities, apologies, and general recommendations.
        4. **ANALYZE:** Rewrite with simple words, explain the reason clearly.
        5. **BUILD:** Use short sentences and clear structure.
        6. **EDGE CASES:** If needed, explain "alternative routes" as other types of transport.
        7. **FAIL-SAFE:** If the original text is already as simple and clear as possible, just repeat it in the required format.
        7. **FINAL ANSWER:** Check for clarity and simplicity.

        **Your answer:**
        Trains will not run between Central and East stations from April 10 to April 15 because of bad weather and repairs. Use other transport.

        ---

        **User request:**
        Level: schoolchild
        Target language: ukrainian
        Text: Due to severe weather conditions and ongoing maintenance work on the railway tracks, City Transport announces that train service between Central and East stations will be temporarily suspended from April 10 to April 15. Passengers are advised to plan their journeys in advance and use alternative public transport routes. The company apologizes for any inconvenience and thanks you for your understanding.

        **Your answer:**
        З 10 до 15 квітня потяги між Центральною та Східною станціями не їздитимуть через погану погоду і ремонт. Будь ласка, обери інший транспорт.
        """)
        let user = LLMMessage(role: .user, content: """
        Level: \(input.complexityLevel.rawValue)
        Target language: \(nativeLang)
        Text: \(text)
        """)
        return [system, user]
    }

    public func buildRequest(text _: String, operation _: InventoryOperation) -> URLRequest {
        URLRequest(url: URL(string: "")!)
    }

    public func parse(responseData: Data) throws -> String {
        guard let str = String(data: responseData, encoding: .utf8) else {
            throw UserFacingError(
                messageKey: .errorParsing,
                adviceKey: .adviceTryAgainLater
            )
        }
        return str
    }

    public func resolveInput(input: OperationInput) throws -> String {
        if let text = input.text, !text.isEmpty {
            return text
        }
        if let url = input.url, !url.isEmpty {
            throw UserFacingError(
                messageKey: .errorUrlNotSupported,
                adviceKey: .adviceCheckConnection
            )
        }
        throw UserFacingError(
            messageKey: .errorNoText,
            adviceKey: .adviceCheckConnection
        )
    }

    public func decodeInput(from data: Data) throws -> OperationInput {
        let params = try JSONDecoder().decode(SimplifyParams.self, from: data)
        return OperationInput(complexityLevel: params.complexityLevel)
    }
}
