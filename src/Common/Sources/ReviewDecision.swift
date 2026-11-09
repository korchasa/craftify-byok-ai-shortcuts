/// Почему оценку сейчас просить можно или нельзя. Значение уходит в журнал
/// как причина, по которой приложение не попросило оценку
public enum ReviewDecision: String {
    /// Пора просить
    case due = "due"
    /// Успешных операций пока меньше порога
    case tooFewSuccesses = "too_few_successes"
    /// В этой версии оценку уже просили
    case alreadyAskedInThisVersion = "already_asked_in_this_version"
    /// Сегодня тот же календарный день, что и первый засчитанный успех
    case firstDayOfUse = "first_day_of_use"
}
