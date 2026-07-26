import Foundation

// [REF:fr:ux.tile-arrange]
/// Дрожание плитки в режиме правки — как у иконок приложений в iOS.
/// Чистые функции без представления, чтобы их можно было проверить юнит-тестом.
public enum OperationTileWiggle {
    /// Период одного качания в секундах
    public static let period: Double = 0.28
    /// Наклон плитки в градусах на пике качания
    private static let maxAngle: Double = 1.4

    /// Угол наклона плитки. Ноль вне режима правки и при включённом системном
    /// «Уменьшении движения» — иначе экран трясётся у тех, кому это мешает.
    /// - Parameters:
    ///   - isEditing: Включён ли режим правки
    ///   - reduceMotion: Включено ли системное «Уменьшение движения»
    /// - Returns: Амплитуда наклона в градусах
    public static func amplitude(isEditing: Bool, reduceMotion: Bool) -> Double {
        guard isEditing, !reduceMotion else { return 0 }
        return maxAngle
    }

    /// Сдвиг фазы, чтобы соседние плитки не качались в такт.
    /// Одинаковый для одной и той же операции и разный для разных.
    /// - Parameter id: Идентификатор операции
    /// - Returns: Сдвиг внутри одного периода, в секундах
    public static func phase(for id: UUID) -> Double {
        let bytes = [id.uuid.0, id.uuid.1, id.uuid.2, id.uuid.3]
        let raw = bytes.reduce(UInt32.zero) { accumulated, byte in
            accumulated << bitsPerByte | UInt32(byte)
        }
        return period * Double(raw) / (Double(UInt32.max) + 1)
    }

    /// Разрядность байта: фаза собирается из первых четырёх байтов идентификатора
    private static let bitsPerByte: UInt32 = 8
}
