import Foundation

/// Протокол для загрузки и извлечения текста из URL
public protocol TextFetching {
    /// Асинхронно загружает и извлекает текст из HTML по URL
    func fetchText(from urlString: String) async throws -> String

    /// Загружает и извлекает текст из HTML по URL с колбэком (для iOS < 15)
    func fetchAndExtractText(from urlString: String, completion: @escaping (Result<String, Error>) -> Void)
}
