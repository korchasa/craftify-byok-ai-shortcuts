import SwiftUI

/// Вспомогательный ключ для передачи высоты контента
public struct ContentHeightKey: PreferenceKey {
    public static var defaultValue: CGFloat = 0
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
