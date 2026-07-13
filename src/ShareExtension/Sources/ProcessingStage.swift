import Foundation

/// Стадия обработки для индикатора прогресса в расширении
public enum ProcessingStage: Equatable {
    /// Загрузка страницы по ссылке
    case fetchingPage
    /// Запрос к языковой модели
    case askingModel
}
