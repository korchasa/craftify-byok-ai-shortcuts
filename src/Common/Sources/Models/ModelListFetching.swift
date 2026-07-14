import Foundation

/// Протокол загрузки актуального списка моделей у провайдера
public protocol ModelListFetching: AnyObject {
    /// Возвращает идентификаторы моделей провайдера (отсортированные)
    func fetchModels(provider: LLMProvider, apiKey: String?) async throws -> [String]
}
