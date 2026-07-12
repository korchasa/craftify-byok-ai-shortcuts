import Foundation

/// Stub для мокирования сетевых ответов в URLSession
public final class URLProtocolStub: URLProtocol {
    public static var response: HTTPURLResponse?
    public static var data: Data?
    public static var error: Error?
    public static var requestObserver: ((URLRequest) -> Void)?

    override public static func canInit(with _: URLRequest) -> Bool {
        true
    }

    override public static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override public func startLoading() {
        if let observer = URLProtocolStub.requestObserver {
            observer(request)
        }
        if let error = URLProtocolStub.error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            if let response = URLProtocolStub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = URLProtocolStub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override public func stopLoading() {}
    public static func reset() {
        response = nil
        data = nil
        error = nil
        requestObserver = nil
    }

    deinit {}
}
