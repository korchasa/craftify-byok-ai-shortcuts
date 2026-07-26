import Foundation

// [REF:fr:ux.tile-arrange]
/// Контекст разбора инвентаря. Кладётся в `JSONDecoder.userInfo` и сообщает,
/// что хотя бы одна операция пришла без идентификатора — значит, хранилище
/// нужно переписать один раз, а не при каждом запуске.
public final class InventoryOperationDecodingContext {
    /// Ключ, под которым контекст лежит в `JSONDecoder.userInfo`
    public static let userInfoKey = CodingUserInfoKey(
        rawValue: "dev.korchasa.Craftify.InventoryOperationDecodingContext"
    )!

    /// Хотя бы одной операции идентификатор был выдан при разборе
    public var didGenerateIdentifier = false

    /// Создаёт пустой контекст со сброшенным флагом
    public init() {}

    deinit {
        // Освобождать нечего: контекст держит только флаг
    }
}
