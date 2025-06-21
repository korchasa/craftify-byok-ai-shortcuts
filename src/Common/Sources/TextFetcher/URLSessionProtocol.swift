import Foundation

/// Протокол для мокирования URLSession, используемый для асинхронной загрузки данных по URL.
public protocol URLSessionProtocol {
    /// Асинхронно загружает данные по указанному URL.
    /// - Parameter url: URL для загрузки данных.
    /// - Returns: Кортеж с данными и ответом URLResponse.
    func data(from url: URL) async throws -> (Data, URLResponse)
    /// Асинхронно загружает данные согласно URLRequest (нужен для установки заголовков, например User-Agent)
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// Реализация протокола URLSessionProtocol для стандартного URLSession
// (extension перенесён в отдельный файл)
