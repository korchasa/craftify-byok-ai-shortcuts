import Foundation

/// Реализация протокола URLSessionProtocol для стандартного URLSession
extension URLSession: URLSessionProtocol {
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await self.data(for: request, delegate: nil)
    }
}
