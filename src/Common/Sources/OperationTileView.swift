import SwiftUI

/// Плитка операции: иконка слева, название и значение настройки справа.
/// Один и тот же вид рисует главный экран и экран выбора трансформации —
/// пользователь расставляет плитки в приложении и узнаёт их в расширении.
public struct OperationTileView: View {
    private let operation: InventoryOperation
    private let symbolColor: Color
    private let textColor: Color
    /// Символ и высота плитки растут вместе с системным размером шрифта
    @ScaledMetric(relativeTo: .body) private var symbolSize: CGFloat = OperationTileConstants.symbolSize
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = OperationTileConstants.height

    /// Создаёт плитку операции
    /// - Parameters:
    ///   - operation: Операция инвентаря
    ///   - symbolColor: Цвет символа операции
    ///   - textColor: Цвет подписей на плитке
    public init(operation: InventoryOperation, symbolColor: Color, textColor: Color) {
        self.operation = operation
        self.symbolColor = symbolColor
        self.textColor = textColor
    }

    /// Значение настройки операции; пустое — у операции нет параметров
    private var settingValue: String {
        OperationDisplay.settingValue(for: operation)
    }

    /// Подпись плитки для VoiceOver: название и заданная настройка
    public var accessibilityText: String {
        let title = OperationDisplay.title(for: operation.operation)
        return settingValue.isEmpty ? title : "\(title), \(settingValue)"
    }

    public var body: some View {
        HStack(spacing: OperationTileConstants.iconSpacing) {
            Image(systemName: operation.operation.sfSymbol)
                .foregroundColor(symbolColor)
                .font(.system(size: symbolSize))
                .fontWeight(.semibold)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: OperationTileConstants.titleSpacing) {
                Text(OperationDisplay.title(for: operation.operation))
                    .font(.craftifyBody)
                    .fontWeight(.bold)
                    .lineLimit(1)
                if !settingValue.isEmpty {
                    Text(settingValue)
                        .font(.craftifyFootnote)
                        .fontWeight(.medium)
                        .opacity(OperationTileConstants.settingOpacity)
                        .lineLimit(1)
                }
            }
            .multilineTextAlignment(.leading)
            Spacer(minLength: CraftifyButtonConstants.spacerMinLength)
        }
        .padding(.horizontal, OperationTileConstants.horizontalPadding)
        .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
        .background(Color(hex: operation.colorHex))
        .foregroundColor(textColor)
        .cornerRadius(OperationTileConstants.cornerRadius)
    }
}
