import Foundation
import UIKit

public final class ClipboardManager: ClipboardManaging {
    public init() {}
    public func copy(text: String) -> Bool {
        UIPasteboard.general.string = text
        return UIPasteboard.general.string == text
    }

    deinit {}
}
