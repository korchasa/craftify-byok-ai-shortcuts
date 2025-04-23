import Foundation

public final class ClipboardManagerStub: NSObject {
    public var copiedText: String?
    public var shouldFail: Bool = false

    override public init() {
        super.init()
    }

    public func copy(text: String) -> Bool {
        if shouldFail {
            return false
        }
        copiedText = text
        return true
    }

    deinit {}
}
