import SwiftUI
import UIKit

/// Карточка операций скруглена только сверху: снизу она уходит за край экрана,
/// и скруглять там нечего
public struct TopRoundedShape: Shape {
    public let radius: CGFloat

    public func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}
