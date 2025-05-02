import Foundation

/// Ошибки, возникающие при загрузке или парсинге текста
public enum FetchError: Error {
    case badURL
    case noData
    case parseError
}
