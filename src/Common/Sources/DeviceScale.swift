import UIKit

/// Масштаб элементов управления, вычисляемый от разрешения экрана:
/// чем шире экран в пунктах, тем крупнее контролы. На iPhone эталонной
/// ширины множитель равен 1, на iPad растёт плавно, а не скачком по идиому.
public enum DeviceScale {
    /// Эталонная короткая сторона экрана в пунктах (iPhone 390pt)
    public static let referenceShortSide: CGFloat = 390
    /// Степень сглаживания роста: 1 — пропорционально экрану, 0 — без роста.
    /// 0.3 даёт ~1.21x на iPad mini, ~1.26x на iPad 11", ~1.34x на iPad 13"
    public static let dampening: CGFloat = 0.3
    /// Нижняя граница множителя (узкие экраны не уменьшаем)
    public static let minFactor: CGFloat = 1.0
    /// Верхняя граница множителя
    public static let maxFactor: CGFloat = 1.4

    /// Множитель размеров контролов (высота кнопок, скругления, иконки)
    public static let controlFactor: CGFloat = factor(forShortSide: currentShortSide)

    /// Экран заметно крупнее эталонного — типографика поднимается на ступень
    public static var isScaledUp: Bool {
        controlFactor >= scaledUpThreshold
    }

    /// Порог, после которого шрифты переходят на более крупные текстовые стили
    public static let scaledUpThreshold: CGFloat = 1.1

    /// Чистая формула масштаба: clamp((side / reference)^dampening)
    public static func factor(forShortSide side: CGFloat) -> CGFloat {
        guard side > 0 else { return minFactor }
        let raw = pow(side / referenceShortSide, dampening)
        return min(max(raw, minFactor), maxFactor)
    }

    /// Короткая сторона текущего экрана в пунктах
    private static var currentShortSide: CGFloat {
        let bounds = UIScreen.main.bounds
        return min(bounds.width, bounds.height)
    }
}
