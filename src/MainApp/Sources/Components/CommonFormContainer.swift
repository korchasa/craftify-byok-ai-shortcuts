import SwiftUI

/// Используйте этот контейнер для всех экранов MainApp с формами и кнопками, кроме HowToUseView.
/// Он обеспечивает единый стиль: разделитель, отступы, фон, шрифты, кнопки.
/// Не используйте для экранов с уникальным макетом (например, HowToUseView).

/// Общий контейнер для экранов MainApp с формами и кнопками
public struct CommonFormContainer<Content: View, Buttons: View>: View {
    public let title: LocalizedStringKey
    public let content: () -> Content
    public let buttons: () -> Buttons

    public init(
        title: LocalizedStringKey,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder buttons: @escaping () -> Buttons
    ) {
        self.title = title
        self.content = content
        self.buttons = buttons
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Divider()
                    .padding(.bottom, FormStyleConstants.dividerBottomPadding)
                VStack(spacing: 0) {
                    content()
                        .padding(.leading, FormStyleConstants.formLeadingPadding)
                        .background(Color.white)
                }
                .padding(.top, FormStyleConstants.formContentTopPadding)
                Spacer(minLength: CraftifyButtonConstants.spacerMinLength)
                buttons()
            }
            .navigationTitle(title)
        }
        .background(Color.white)
    }
}
