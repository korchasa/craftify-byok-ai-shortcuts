import SwiftUI

// [REF:fr:ux.tile-arrange]
/// Плитка операции на главном экране. В покое — кнопка, открывающая правку.
/// В режиме правки плитка дрожит и получает кружок с минусом, как иконка
/// приложения на домашнем экране iOS.
public struct OperationTileButton: View {
    private let operation: InventoryOperation
    private let palette: MainAppColorPaletteProviding
    private let isEditing: Bool
    private let onEdit: () -> Void
    private let onDelete: () -> Void
    private let dragItem: (() -> NSItemProvider)?
    private let onLongPress: (() -> Void)?
    /// Ширина ячейки — её знает только сетка, а превью перетаскивания без
    /// родителя растянулось бы во всю доступную ширину
    private let cellWidth: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Фаза качания: пока false — плитка отклонена в одну сторону, потом в другую
    @State private var isSwungForward = false
    /// Удержание уже сработало, и отпускание пальца не должно открыть форму правки
    @State private var didLongPress = false

    /// Создаёт плитку операции для главного экрана
    /// - Parameters:
    ///   - operation: Операция инвентаря
    ///   - palette: Палитра текущей темы
    ///   - isEditing: Включён ли режим правки
    ///   - onEdit: Открыть форму правки
    ///   - onDelete: Запросить удаление операции
    ///   - dragItem: Груз перетаскивания. `nil` — плитку тащить нельзя
    ///   - onLongPress: Что делать на удержании плитки. `nil` — ничего
    ///   - cellWidth: Ширина ячейки сетки — в ней едет превью перетаскивания
    public init(
        operation: InventoryOperation,
        palette: MainAppColorPaletteProviding,
        isEditing: Bool,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        cellWidth: CGFloat,
        dragItem: (() -> NSItemProvider)? = nil,
        onLongPress: (() -> Void)? = nil
    ) {
        self.operation = operation
        self.palette = palette
        self.isEditing = isEditing
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.cellWidth = cellWidth
        self.dragItem = dragItem
        self.onLongPress = onLongPress
    }

    /// Наклон плитки в градусах: ноль вне правки и при «Уменьшении движения»
    private var amplitude: Double {
        OperationTileWiggle.amplitude(isEditing: isEditing, reduceMotion: reduceMotion)
    }

    private var tile: OperationTileView {
        OperationTileView(
            operation: operation,
            symbolColor: palette.operationSymbolColor(),
            textColor: palette.primaryButtonText()
        )
    }

    /// Кружок с минусом поверх левого верхнего угла плитки.
    /// Красный системный — тот же сигнал удаления, что и везде в iOS.
    private var deleteBadge: some View {
        Button(action: onDelete) {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(
                        width: OperationTileConstants.deleteBadgeSize,
                        height: OperationTileConstants.deleteBadgeSize
                    )
                Image(systemName: "minus")
                    .font(.system(size: OperationTileConstants.deleteBadgeSymbolSize, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(L10n.homeDelete)
        .accessibilityIdentifier("operation_delete_\(operation.operation.rawValue)")
        .offset(
            x: -OperationTileConstants.deleteBadgeOffset,
            y: -OperationTileConstants.deleteBadgeOffset
        )
    }

    /// Плитка и бейдж — соседи в ZStack, а не вложенные друг в друга кнопки:
    /// вложенную кнопку родительский элемент доступности проглатывает, и до
    /// минуса не добираются ни VoiceOver, ни UI-тест
    public var body: some View {
        ZStack(alignment: .topLeading) {
            draggableTile
            if isEditing {
                deleteBadge
            }
        }
        .rotationEffect(.degrees(isSwungForward ? amplitude : -amplitude))
        .animation(wiggleAnimation, value: isSwungForward)
        .onAppear { isSwungForward = isEditing }
        .onChange(of: isEditing) { newValue in
            isSwungForward = newValue
            // Палец мог уехать после удержания, и кнопка своего нажатия не получила.
            // Смена режима — надёжная точка, где флаг перестаёт быть нужен
            didLongPress = false
        }
    }

    /// Перетаскивание висит на самой плитке, а не на ZStack вместе с бейджем.
    /// Систему интересует именно источник переноса: при «приподнятии» она
    /// снимает его как есть, и вместе с ZStack в снимок попадал бы вынесенный
    /// за угол минус, а вокруг — непрозрачный прямоугольник по границам снимка
    @ViewBuilder
    private var draggableTile: some View {
        if let dragItem {
            tileButton
                .contentShape(.dragPreview, previewShape)
                .onDrag(dragItem) { dragPreview }
        } else if let onLongPress {
            // Вне режима правки удержание его включает — как на домашнем экране
            // iOS, где иконки начинают дрожать, не дожидаясь отдельной кнопки.
            // Жест именно одновременный: собственный жест кнопки забирает нажатие
            // себе, и обычный `onLongPressGesture` поверх неё не доходит
            tileButton
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: OperationTileConstants.longPressToEditDuration)
                        .onEnded { _ in
                            didLongPress = true
                            onLongPress()
                        }
                )
        } else {
            tileButton
        }
    }

    /// Кнопка-плитка без бейджа
    private var tileButton: some View {
        // В режиме правки тап ничего не открывает, но кнопку не выключаем:
        // выключенная бледнеет, а плитка должна оставаться такой же яркой,
        // как иконка приложения на домашнем экране.
        // Отпускание пальца после удержания — не тап: кнопка всё равно получает
        // своё нажатие, и без флага удержание заодно открывало бы форму правки
        Button(action: {
            if didLongPress {
                didLongPress = false
                return
            }
            if !isEditing {
                onEdit()
            }
        }) {
            tile
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(isEditing ? L10n.homeSortHandle : tile.accessibilityText)
        .accessibilityHint(isEditing ? L10n.homeSortHint : "")
        .accessibilityIdentifier("operation_row_\(operation.operation.rawValue)")
    }

    /// Картинка, которая едет под пальцем. Ширину задаём сами: у превью нет
    /// родителя, который растянул бы его по ячейке
    private var dragPreview: some View {
        tile
            .frame(width: cellWidth)
            .contentShape(.dragPreview, previewShape)
    }

    /// Форма подложки под превью. Без неё система подкладывает непрозрачный
    /// прямоугольник, и он торчит из-под скруглённых углов плитки
    private var previewShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: OperationTileConstants.cornerRadius, style: .continuous)
    }

    /// Качание идёт вечным циклом со сдвигом фазы, чтобы соседние плитки
    /// не качались в такт. Когда амплитуда нулевая, анимации нет вовсе.
    private var wiggleAnimation: Animation? {
        guard amplitude > 0 else { return nil }
        return .easeInOut(duration: OperationTileWiggle.period)
            .repeatForever(autoreverses: true)
            .delay(OperationTileWiggle.phase(for: operation.id))
    }
}
