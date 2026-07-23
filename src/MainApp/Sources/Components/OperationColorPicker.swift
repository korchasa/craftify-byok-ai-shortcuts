import SwiftUI

/// Компактный выбор цвета операции: иконка в текущем цвете открывает
/// всплывающую палитру. Одна строка формы вместо горизонтальной ленты —
/// на iPad в ландшафте лента цветов и кнопка удаления не помещались в лист.
public struct OperationColorPicker: View {
    private let symbol: String
    private let palette: [String]
    @Binding private var selectedHex: String
    private let accessibilityID: String

    @Environment(\.colorPalette) private var colorPalette
    @State private var isPresented = false

    private static let baseIconSize: CGFloat = 34
    private static let iconSize: CGFloat = baseIconSize * DeviceScale.controlFactor
    private static let symbolScale: CGFloat = 0.48
    private static let hintSize: CGFloat = 12
    private static let popoverWidth: CGFloat = 240
    private static let swatchBorderWidth: CGFloat = 1
    private static let swatchBorderOpacity: CGFloat = 0.15

    public init(symbol: String, palette: [String], selectedHex: Binding<String>, accessibilityID: String) {
        self.symbol = symbol
        self.palette = palette
        self._selectedHex = selectedHex
        self.accessibilityID = accessibilityID
    }

    public var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack(spacing: FormStyleConstants.dividerBottomPadding) {
                icon
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: Self.hintSize, weight: .semibold))
                    .foregroundColor(colorPalette.secondaryText())
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityID)
        .accessibilityLabel(L10n.color)
        .popover(isPresented: $isPresented) {
            palettePopover.compactPopover()
        }
    }

    private var icon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: selectedHex))
                .frame(width: Self.iconSize, height: Self.iconSize)
            Image(systemName: symbol)
                .font(.system(size: Self.iconSize * Self.symbolScale, weight: .semibold))
                .foregroundColor(colorPalette.operationSymbolColor())
                .accessibilityHidden(true)
        }
    }

    private var palettePopover: some View {
        let columns = [GridItem(
            .adaptive(minimum: ColorPickerLayoutConstants.circleSize + ColorPickerLayoutConstants.circleSpacing),
            spacing: ColorPickerLayoutConstants.circleSpacing
        )]
        return LazyVGrid(columns: columns, spacing: ColorPickerLayoutConstants.circleSpacing) {
            ForEach(palette, id: \.self) { hex in
                Button {
                    selectedHex = hex
                    isPresented = false
                } label: {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: ColorPickerLayoutConstants.circleSize, height: ColorPickerLayoutConstants.circleSize)
                        // Выбранный — толстое акцентное кольцо; остальные — тонкая
                        // обводка, иначе бледные цвета сливаются с белым фоном палитры
                        .overlay(
                            Circle()
                                .stroke(
                                    selectedHex == hex ? Color.accentColor : Color.primary.opacity(Self.swatchBorderOpacity),
                                    lineWidth: selectedHex == hex ? ColorPickerLayoutConstants.borderWidth : Self.swatchBorderWidth
                                )
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.colorAccessibilityFormat(hex))
                .accessibilityAddTraits(selectedHex == hex ? .isSelected : [])
                .accessibilityIdentifier("operation_color_swatch_\(hex)")
            }
        }
        .padding()
        .frame(width: Self.popoverWidth)
    }
}

private extension View {
    /// На iPad палитра остаётся компактным popover; на iPhone (iOS 16.4+)
    /// тоже, иначе система сама покажет её листом
    @ViewBuilder
    func compactPopover() -> some View {
        if #available(iOS 16.4, *) {
            presentationCompactAdaptation(.popover)
        } else {
            self
        }
    }
}
