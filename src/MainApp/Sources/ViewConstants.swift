import SwiftUI

/// Общие константы для настройки отображения View
public enum ViewConstants {
    /// Неограниченное количество строк для lineLimit
    public static let unlimitedLineLimit: Int = .max
    /// Значение fixedSize(horizontal: ...) по умолчанию
    public static let fixedSizeHorizontal: Bool = false
    /// Значение fixedSize(vertical: ...) по умолчанию
    public static let fixedSizeVertical: Bool = true
    /// Максимальная ширина контента корневых экранов: на iPad без ограничения
    /// контент растягивается на всю ширину и становится нечитаемым
    public static let rootContentMaxWidth: CGFloat = 700
}
