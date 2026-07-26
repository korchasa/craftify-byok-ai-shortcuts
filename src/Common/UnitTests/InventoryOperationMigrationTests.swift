import XCTest

/// Проверяет выдачу устойчивых идентификаторов операциям, сохранённым до обновления
public final class InventoryOperationMigrationTests: XCTestCase {
    private static let storageKey = "CraftifyInventory"

    /// Инвентарь в том виде, в каком его писали прошлые версии: поля `id` в JSON нет
    private static let legacyJSON = Data("""
    [
      {"operation":"translate","params":"","colorHex":"3288bd"},
      {"operation":"simplify","params":"","colorHex":"fdae61"}
    ]
    """.utf8)

    private func makeDefaults() -> UserDefaults {
        let suite = "InventoryOperationMigrationTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suite) else {
            fatalError("UserDefaults suite \(suite) unavailable")
        }
        defaults.set(Self.legacyJSON, forKey: Self.storageKey)
        return defaults
    }

    /// Старые записи получают идентификаторы один раз: после перезагрузки они те же самые
    public func testLegacyRecordsGetStableIdentifiersOnce() {
        let defaults = makeDefaults()
        let manager = InventoryManager(userDefaults: defaults, migratesIdentifiers: true)
        let firstIDs = manager.inventory.map(\.id)
        XCTAssertEqual(firstIDs.count, 2)
        XCTAssertEqual(Set(firstIDs).count, 2, "Идентификаторы двух операций должны различаться")

        let reloaded = InventoryManager(userDefaults: defaults, migratesIdentifiers: true)
        XCTAssertEqual(reloaded.inventory.map(\.id), firstIDs, "Повторная загрузка не должна менять идентификаторы")
    }

    /// Расширение читает старые записи, но хранилище не переписывает
    public func testExtensionReadsLegacyRecordsWithoutRewritingStorage() {
        let defaults = makeDefaults()
        let manager = InventoryManager(userDefaults: defaults, migratesIdentifiers: false)
        XCTAssertEqual(manager.inventory.count, 2)
        XCTAssertEqual(defaults.data(forKey: Self.storageKey), Self.legacyJSON, "Расширение не должно писать в общее хранилище")
    }

    /// Разбор без контекста миграции в `userInfo` не падает и раздаёт идентификаторы
    public func testDecodingWithoutMigrationContextStillYieldsIdentifiers() throws {
        let decoded = try JSONDecoder().decode([InventoryOperation].self, from: Self.legacyJSON)
        XCTAssertEqual(decoded.count, 2)
        XCTAssertEqual(Set(decoded.map(\.id)).count, 2)
    }

    /// Записи с сохранённым идентификатором его не теряют
    public func testStoredIdentifierIsPreservedOnDecode() throws {
        let original = InventoryOperation(operation: .correct, params: Data(), colorHex: "d53e4f")
        let data = try JSONEncoder().encode([original])
        let decoded = try JSONDecoder().decode([InventoryOperation].self, from: data)
        XCTAssertEqual(decoded.first?.id, original.id)
    }
}
