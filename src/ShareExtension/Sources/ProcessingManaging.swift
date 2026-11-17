import Foundation

public protocol ProcessingManaging: AnyObject {
    func process(text: String, operation: InventoryOperation, completion: @escaping (Result<String, Error>) -> Void)

    /// Обработка с промежуточными результатами
    /// - Parameters:
    ///   - text: Текст для обработки
    ///   - operation: Операция
    ///   - onPartial: Получает накопленный текст ответа, пока модель его пишет
    ///   - completion: Получает итог
    func process(
        text: String,
        operation: InventoryOperation,
        onPartial: ((String) -> Void)?,
        completion: @escaping (Result<String, Error>) -> Void
    )
    func cancel()
}

public extension ProcessingManaging {
    /// Обработка без промежуточных результатов: итог приходит одним вызовом
    func process(
        text: String,
        operation: InventoryOperation,
        onPartial _: ((String) -> Void)?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        process(text: text, operation: operation, completion: completion)
    }
}
