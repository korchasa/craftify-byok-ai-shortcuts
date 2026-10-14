import SwiftUI

/// Строка формы «подпись — значение». В обычных размерах шрифта значение стоит
/// справа от подписи. На размерах «Универсального доступа» оно уходит под
/// подпись и получает всю ширину: в одну строку оба не помещаются, и названия
/// вроде «OpenAI» рвались переносом посреди слова
public struct FormRow<Title: View, Value: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let title: Title
    private let value: Value

    /// Создаёт строку формы
    /// - Parameters:
    ///   - title: Подпись строки
    ///   - value: Значение или элемент управления
    public init(@ViewBuilder title: () -> Title, @ViewBuilder value: () -> Value) {
        self.title = title()
        self.value = value()
    }

    public var body: some View {
        // [REF:fr:ux.dynamic-type]
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: FormStyleConstants.dividerBottomPadding) {
                title
                value
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            HStack {
                title
                Spacer()
                value
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}
