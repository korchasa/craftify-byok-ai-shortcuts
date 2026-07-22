import UIKit

/// Масштаб элементов управления по типу устройства: на iPad контролы
/// увеличиваются, а не сохраняют iPhone-размеры.
public enum DeviceScale {
    /// Приложение запущено на iPad
    public static let isPad = UIDevice.current.userInterfaceIdiom == .pad
    /// Множитель размеров контролов (высота кнопок, скругления, иконки)
    public static let controlFactor: CGFloat = isPad ? 1.25 : 1.0
}
