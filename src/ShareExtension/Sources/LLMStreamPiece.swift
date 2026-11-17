import Foundation

/// Что принесло одно событие потокового ответа
public enum LLMStreamPiece: Equatable {
    /// Очередной кусок текста ответа
    case text(String)
    /// Ответ закончен
    case done
    /// Служебное событие без текста
    case skip
}
