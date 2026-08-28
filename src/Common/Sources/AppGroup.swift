import Foundation

/// Идентификаторы общего хранилища, которым пользуются приложение и расширение.
///
/// Значения приходят из Info.plist, куда их подставляет сборка, а не зашиты в
/// код. Благодаря этому копия, собранная с другим идентификатором бандла,
/// работает со своим хранилищем и не пишет в данные версии, установленной рядом.
public enum AppGroup {
    /// Suite name для UserDefaults, общий у приложения и расширения.
    public static let identifier = required("AppGroupIdentifier")

    /// Access group для Keychain — та же группа с префиксом команды.
    public static let keychainAccessGroup = required("KeychainAccessGroup")

    /// Якорь, по которому находится бандл с этим кодом: приложение, расширение
    /// или тестовый бандл. `Bundle.main` здесь не подходит — под тестами это
    /// исполняемый файл xctest, у которого нужных ключей нет.
    private final class BundleAnchor {
        init() {}
        deinit {}
    }

    private static func required(_ key: String) -> String {
        let bundle = Bundle(for: BundleAnchor.self)
        guard let value = bundle.object(forInfoDictionaryKey: key) as? String, !value.isEmpty else {
            fatalError("\(key) отсутствует в Info.plist бандла \(bundle.bundleIdentifier ?? "?") — сборка не подставила значение")
        }
        return value
    }
}
