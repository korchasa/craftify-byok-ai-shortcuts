import Foundation

// [REF:fr:ux.tile-arrange]
/// Операция инвентаря Craftify (тип, параметры, шаблон промпта)
public struct InventoryOperation: Codable, Equatable, Hashable, Identifiable {
    /// Устойчивый идентификатор: переживает правку настройки и перестановку,
    /// поэтому расстановка плиток принадлежит операции, а не её месту в массиве
    public let id: UUID
    /// Тип операции (translate, simplify, correct, explain)
    public let operation: OperationKind
    /// Сериализованные параметры операции
    public let params: Data // Encoded params (type depends on operation)
    /// Цвет операции (hex, например, "3288bd")
    public let colorHex: String
    /// Отредактированный пользователем системный промпт; nil — используется
    /// дефолтный текст, собранный из шаблона операции (старые записи без
    /// этого поля декодируются как nil)
    public let customPrompt: String?
    /// Ячейка сетки, которую занимает плитка. Между занятыми ячейками могут
    /// быть пустые: пользователь ставит плитку куда хочет, и дырка не
    /// схлопывается. Старые записи без этого поля получают номер по порядку
    public let slot: Int

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Инициализация InventoryOperation
    /// - Parameters:
    ///   - operation: Тип операции
    ///   - params: Сериализованные параметры
    ///   - colorHex: Цвет операции (hex)
    ///   - customPrompt: Пользовательский системный промпт (nil — из шаблона)
    ///   - id: Устойчивый идентификатор (по умолчанию — новый)
    ///   - slot: Ячейка сетки (по умолчанию — первая)
    public init(
        operation: OperationKind,
        params: Data,
        colorHex: String = "3288bd",
        customPrompt: String? = nil,
        id: UUID = UUID(),
        slot: Int = 0
    ) {
        self.id = id
        self.operation = operation
        self.params = params
        self.colorHex = colorHex
        self.customPrompt = customPrompt
        self.slot = slot
    }

    /// Разбор записи инвентаря. Записи, сохранённые до появления полей `id` и
    /// `slot`, не отбрасываются: идентификатор выдаётся новый, а ячейка
    /// остаётся неизвестной и проставляется миграцией по текущему порядку.
    /// Когда в `userInfo` лежит контекст миграции, ему сообщают, что запись
    /// старая; без контекста разбор всё равно проходит — голым `JSONDecoder`
    /// пользуются и тесты, и другие места кода.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let storedID = try container.decodeIfPresent(UUID.self, forKey: .id)
        let storedSlot = try container.decodeIfPresent(Int.self, forKey: .slot)
        self.id = storedID ?? UUID()
        self.slot = storedSlot ?? Self.unassignedSlot
        self.operation = try container.decode(OperationKind.self, forKey: .operation)
        self.params = try container.decode(Data.self, forKey: .params)
        self.colorHex = try container.decode(String.self, forKey: .colorHex)
        self.customPrompt = try container.decodeIfPresent(String.self, forKey: .customPrompt)
        if storedID == nil || storedSlot == nil {
            let context = decoder.userInfo[InventoryOperationDecodingContext.userInfoKey]
            (context as? InventoryOperationDecodingContext)?.didGenerateIdentifier = true
        }
    }

    /// Ячейка ещё не назначена: так помечены записи, сохранённые до появления сетки
    public static let unassignedSlot = -1

    /// Копия операции с другим пользовательским промптом
    public func with(customPrompt: String?) -> InventoryOperation {
        copy(customPrompt: customPrompt)
    }

    /// Копия операции с подменённым идентификатором.
    /// Нужна там, где операцию пересобирает фабрика: та выдаёт свежий `UUID`,
    /// а правка должна остаться правкой прежней плитки.
    public func with(id: UUID) -> InventoryOperation {
        copy(id: id)
    }

    /// Копия операции, переставленная в другую ячейку сетки
    public func with(slot: Int) -> InventoryOperation {
        copy(slot: slot)
    }

    private func copy(
        customPrompt: String?? = nil,
        id: UUID? = nil,
        slot: Int? = nil
    ) -> InventoryOperation {
        InventoryOperation(
            operation: operation,
            params: params,
            colorHex: colorHex,
            customPrompt: customPrompt ?? self.customPrompt,
            id: id ?? self.id,
            slot: slot ?? self.slot
        )
    }
}
