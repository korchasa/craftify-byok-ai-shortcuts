import SwiftUI

public struct DarkMainAppColorPalette: MainAppColorPaletteProviding {
    // MARK: - ColorPaletteProviding

    public func backgroundColor() -> Color { background() }
    public func textColor() -> Color { primaryText() }
    public func secondaryTextColor() -> Color { secondaryText() }
    public func destructiveColor() -> Color { destructive() }
    public func linkColor() -> Color { link() }
    public func secondaryColor() -> Color { secondaryButton() }
    public func palette() -> [String] { [
        "ef476f", "f78c6b", "ffd166", "83d483", "06d6a0",
        "0cb0a9", "118ab2", "0c637f", "073b4c"
    ] }
    public let circleSize: CGFloat = ColorPaletteConstants.circleSize
    public let circleSpacing: CGFloat = 12
    public let borderWidth: CGFloat = 3
    public let verticalSpacing: CGFloat = 8
    public let bottomPadding: CGFloat = 4
    public init() {}

    // MARK: - MainAppColorPaletteProviding

    public func background() -> Color { Color(red: ColorPaletteConstants.backgroundDarkRed, green: ColorPaletteConstants.backgroundDarkGreen, blue: ColorPaletteConstants.backgroundDarkBlue) }
    public func primaryText() -> Color { Color.white }
    public func secondaryText() -> Color { Color(red: ColorPaletteConstants.secondaryTextRed, green: ColorPaletteConstants.secondaryTextGreen, blue: ColorPaletteConstants.secondaryTextBlue) }
    public func primaryButton() -> Color { Color(red: ColorPaletteConstants.primaryRed, green: ColorPaletteConstants.primaryGreen, blue: ColorPaletteConstants.primaryBlue) }
    public func primaryButtonText() -> Color { background() }
    public func secondaryButton() -> Color { Color(red: ColorPaletteConstants.secondaryRed, green: ColorPaletteConstants.secondaryGreen, blue: ColorPaletteConstants.secondaryBlue) }
    public func secondaryButtonText() -> Color { background() }
    public func destructive() -> Color { Color(red: ColorPaletteConstants.destructiveRed, green: ColorPaletteConstants.destructiveGreen, blue: ColorPaletteConstants.destructiveBlue) }
    public func link() -> Color { Color(red: ColorPaletteConstants.linkRed, green: ColorPaletteConstants.linkGreen, blue: ColorPaletteConstants.linkBlue) }
}
