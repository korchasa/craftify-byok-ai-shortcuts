import XCTest

/// Тесты проверяют корректное формирование дефолтного инвентаря операций.
public final class InventoryManagerDefaultOperationsTests: XCTestCase {
    private func makeManager() -> InventoryManager {
        // Используем отдельный suite, чтобы не затронуть реальные данные.
        let defaults = UserDefaults(suiteName: "InventoryManagerDefaultOperationsTests")!
        defaults.removePersistentDomain(forName: "InventoryManagerDefaultOperationsTests")
        return InventoryManager(userDefaults: defaults)
    }

    /// Проверяет, что fillWithDefaultOperationsIfNeeded формирует правильный набор операций
    public func testFillWithDefaultOperationsIfNeeded() {
        // Arrange
        let manager = makeManager()
        manager.clearInventory()

        // Act
        manager.fillWithDefaultOperationsIfNeeded()
        let operations = manager.inventory

        // Assert – должен быть не пустой
        XCTAssertFalse(operations.isEmpty)

        // Получаем код языка устройства
        let deviceLang = Locale.current.language.languageCode?.identifier ?? "en"

        // Считаем операции по типу
        let kinds = operations.map(\.operation)
        XCTAssertTrue(kinds.contains(.translate))
        XCTAssertTrue(kinds.contains(.simplify))
        XCTAssertTrue(kinds.contains(.correct))
        XCTAssertTrue(kinds.contains(.explain))
        XCTAssertTrue(kinds.contains(.summarize))

        // Проверяем summarize длину
        if let summarizeOp = operations.first(where: { $0.operation == .summarize }) {
            if let params = try? JSONDecoder().decode(SummarizeParams.self, from: summarizeOp.params) {
                XCTAssertEqual(params.length, "9-10 sentences")
            } else {
                XCTFail("Не удалось декодировать SummarizeParams")
            }
        } else {
            XCTFail("Операция summarize отсутствует")
        }

        // Проверяем перевод на синдарин
        XCTAssertTrue(operations.contains { op in
            op.operation == .translate &&
                (try? JSONDecoder().decode(TranslateParams.self, from: op.params).targetLanguage) == "sjn"
        })

        // Проверяем перевод на язык устройства
        XCTAssertTrue(operations.contains { op in
            op.operation == .translate &&
                (try? JSONDecoder().decode(TranslateParams.self, from: op.params).targetLanguage) == deviceLang
        })

        // Проверяем правила для английского
        let englishTranslations = operations.filter { op in
            op.operation == .translate &&
                (try? JSONDecoder().decode(TranslateParams.self, from: op.params).targetLanguage) == "en"
        }
        if deviceLang == "en" {
            // Должен быть ровно один (как перевод на язык устройства)
            XCTAssertEqual(englishTranslations.count, 1)
        } else {
            // Когда язык устройства не английский, перевод на английский должен присутствовать отдельно
            XCTAssertEqual(englishTranslations.count, 1)
        }

        // Проверяем отсутствие дубликатов translate для одного языка
        var seenLangs = Set<String>()
        for op in operations where op.operation == .translate {
            if let lang = try? JSONDecoder().decode(TranslateParams.self, from: op.params).targetLanguage {
                XCTAssertFalse(seenLangs.contains(lang), "Дубликат перевода на язык \(lang)")
                seenLangs.insert(lang)
            }
        }

        // Проверка общего количества операций
        let expectedCount = deviceLang == "en" ? 6 : 7
        XCTAssertEqual(operations.count, expectedCount)

        // Проверяем порядок операций
        let deviceLangTranslateCode = deviceLang
        var expectedSequence: [(InventoryOperation) -> Bool] = []
        if deviceLang == "en" {
            expectedSequence = [
                { self.matchTranslate(op: $0, lang: "en") },
                { $0.operation == .simplify },
                { $0.operation == .correct },
                { $0.operation == .summarize },
                { $0.operation == .explain },
                { self.matchTranslate(op: $0, lang: "sjn") }
            ]
        } else {
            expectedSequence = [
                { self.matchTranslate(op: $0, lang: deviceLangTranslateCode) },
                { self.matchTranslate(op: $0, lang: "en") },
                { $0.operation == .simplify },
                { $0.operation == .correct },
                { $0.operation == .summarize },
                { $0.operation == .explain },
                { self.matchTranslate(op: $0, lang: "sjn") }
            ]
        }

        XCTAssertEqual(operations.count, expectedSequence.count)
        for (idx, matcher) in expectedSequence.enumerated() {
            XCTAssertTrue(matcher(operations[idx]), "Операция под индексом \(idx) не соответствует ожидаемой")
        }
    }

    // MARK: - Helpers

    private func matchTranslate(op: InventoryOperation, lang: String) -> Bool {
        guard op.operation == .translate,
              let code = try? JSONDecoder().decode(TranslateParams.self, from: op.params).targetLanguage else { return false }
        return code == lang
    }
}
