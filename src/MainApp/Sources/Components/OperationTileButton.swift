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
    private let dragItem: () -> NSItemProvider
    private let onEnterEditing: () -> Void
    /// Ширина ячейки — её знает только сетка, а превью перетаскивания без
    /// родителя растянулось бы во всю доступную ширину
    private let cellWidth: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Фаза качания: пока false — плитка отклонена в одну сторону, потом в другую
    @State private var isSwungForward = false

    /// Создаёт плитку операции для главного экрана
    /// - Parameters:
    ///   - operation: Операция инвентаря
    ///   - palette: Палитра текущей темы
    ///   - isEditing: Включён ли режим правки
    ///   - onEdit: Открыть форму правки
    ///   - onDelete: Запросить удаление операции
    ///   - dragItem: Груз перетаскивания
    ///   - onEnterEditing: Включить режим правки — вызывается на удержании
    ///   - cellWidth: Ширина ячейки сетки — в ней едет превью перетаскивания
    public init(
        operation: InventoryOperation,
        palette: MainAppColorPaletteProviding,
        isEditing: Bool,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        cellWidth: CGFloat,
        dragItem: @escaping () -> NSItemProvider,
        onEnterEditing: @escaping () -> Void
    ) {
        self.operation = operation
        self.palette = palette
        self.isEditing = isEditing
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.cellWidth = cellWidth
        self.dragItem = dragItem
        self.onEnterEditing = onEnterEditing
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
        }
    }

    /// Перетаскивание висит на самой плитке, а не на ZStack вместе с бейджем.
    /// Систему интересует именно источник переноса: при «приподнятии» она
    /// снимает его как есть, и вместе с ZStack в снимок попадал бы вынесенный
    /// за угол минус, а вокруг — непрозрачный прямоугольник по границам снимка.
    ///
    /// Перенос включён всегда, а не только в режиме правки. Раньше `.onDrag`
    /// появлялся вместе с режимом — то есть ровно в тот момент, когда палец уже
    /// держал плитку. Система вешает распознаватель переноса на готовое
    /// представление и не подхватывает уже идущее касание, поэтому удержание
    /// обрывалось и тащить приходилось со второго раза
    private var draggableTile: some View {
        tileButton
            .contentShape(.dragPreview, previewShape)
            .onDrag(startDrag) { dragPreview }
    }

    /// Поднимает плитку и заодно включает режим правки — как на домашнем экране
    /// iOS, где иконки начинают дрожать от того же удержания, которым их тащат.
    /// Система зовёт это на «приподнятии», то есть после удержания и до первого
    /// движения пальца: отпустив палец сразу, пользователь просто остаётся в
    /// режиме правки
    private func startDrag() -> NSItemProvider {
        onEnterEditing()
        return dragItem()
    }

    /// Кнопка-плитка без бейджа
    private var tileButton: some View {
        // В режиме правки тап ничего не открывает, но кнопку не выключаем:
        // выключенная бледнеет, а плитка должна оставаться такой же яркой,
        // как иконка приложения на домашнем экране.
        // Открывать ли форму, решает `onEdit` на стороне экрана: наше `isEditing`
        // к моменту отпускания пальца бывает устаревшим, а экран знает режим точно
        Button(action: onEdit) {
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
