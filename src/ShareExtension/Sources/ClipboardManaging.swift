import Foundation

public protocol ClipboardManaging: AnyObject {
    func copy(text: String) -> Bool
}
