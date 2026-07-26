import SwiftUI

/// Геометрия плитки операции. Общая для главного экрана и экрана выбора
/// трансформации: пользователь расставляет плитки в приложении и должен видеть
/// ровно то же самое, когда открывает расширение.
public enum OperationTileConstants {
    /// Число колонок в сетке плиток
    public static let columns: Int = 2
    /// Отступ между плитками по обеим осям
    public static let gridSpacing: CGFloat = 10
    /// Высота плитки: название и значение настройки помещаются в две строки
    public static let height: CGFloat = 64
    /// Скругление плитки
    public static let cornerRadius: CGFloat = 18
    /// Горизонтальный внутренний отступ плитки
    public static let horizontalPadding: CGFloat = 12
    /// Отступ между иконкой и подписями
    public static let iconSpacing: CGFloat = 10
    /// Отступ между названием операции и значением её настройки
    public static let titleSpacing: CGFloat = 2
    /// Размер символа операции
    public static let symbolSize: CGFloat = 20
    /// Прозрачность значения настройки на плитке
    public static let settingOpacity: Double = 0.75
    /// Диаметр кружка с минусом в режиме правки
    public static let deleteBadgeSize: CGFloat = 22
    /// Насколько кружок с минусом вынесен за угол плитки
    public static let deleteBadgeOffset: CGFloat = 6
    /// Размер символа минуса внутри кружка
    public static let deleteBadgeSymbolSize: CGFloat = 11
    /// Толщина пунктирной рамки пустой ячейки
    public static let emptyCellBorderWidth: CGFloat = 1.5
    /// Длина штриха пунктирной рамки пустой ячейки
    public static let emptyCellDashLength: CGFloat = 5
    /// Насколько заметна рамка пустой ячейки
    public static let emptyCellBorderOpacity: Double = 0.35
    /// Подсветка ячейки, над которой держат перетаскиваемую плитку
    public static let dropHighlightOpacity: Double = 0.18
    /// Сколько держать плитку, чтобы включился режим правки. Столько же
    /// система ждёт на удержании иконки домашнего экрана
    public static let longPressToEditDuration: Double = 0.5
}
