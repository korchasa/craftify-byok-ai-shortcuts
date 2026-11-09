import Foundation

/// Когда главный экран начинает отсчёт до просьбы об оценке.
///
/// Apple советует просить оценку в конце законченного дела, а не при открытии
/// приложения. Законченное дело в приложении — закрытый экран задачи: форма
/// добавления операции, форма правки или настройки. Поэтому отсчёт начинается
/// только с их закрытия, а открытие нового экрана или уход приложения с
/// переднего плана его отменяет. Сам отсчёт и просьбу ведёт `RootView`; здесь
/// только решение, чтобы его можно было проверить тестами.
public struct ReviewPromptTrigger: Equatable {
    /// Номер идущего отсчёта; nil — отсчёта нет. Каждое закрытие экрана задачи
    /// даёт новый номер, и по его смене SwiftUI перезапускает ожидание
    public private(set) var countdown: Int?
    private var lastCountdown = 0
    private var isTaskSheetShown = false
    private var isInForeground = true

    public init() {}

    /// Экран задачи открылся или закрылся
    /// - Parameter isShown: открыт ли сейчас хотя бы один экран задачи
    public mutating func taskSheetChanged(isShown: Bool) {
        // [REF:fr:ux.review-request] — отсчёт с закрытия экрана задачи
        let wasShown = isTaskSheetShown
        isTaskSheetShown = isShown
        if isShown {
            countdown = nil
        } else if wasShown, isInForeground {
            lastCountdown += 1
            countdown = lastCountdown
        }
    }

    /// Приложение вышло на передний план или ушло с него. Возвращение отсчёт
    /// не начинает: при открытии приложения оценку не просят
    /// - Parameter isActive: активна ли сцена
    public mutating func foregroundChanged(isActive: Bool) {
        isInForeground = isActive
        if !isActive {
            countdown = nil
        }
    }

    /// Можно ли просить оценку, когда отсчёт с этим номером истёк: его никто
    /// не отменил, приложение на переднем плане и экран задачи не открыт
    /// - Parameter id: номер отсчёта, который истёк
    public func mayAsk(afterCountdown id: Int) -> Bool {
        countdown == id && isInForeground && !isTaskSheetShown
    }
}
