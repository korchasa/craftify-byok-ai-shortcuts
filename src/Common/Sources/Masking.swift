import Foundation

private let maskMinKeyLength = 8
private let maskSuffixLength = 4

/// Универсальная функция маскирования API-ключа
@inline(__always)
public func maskKey(_ key: String?) -> String {
    guard let key, key.count > maskMinKeyLength else {
        return String(repeating: "*", count: maskMinKeyLength)
    }
    let starsCount = key.count - maskSuffixLength
    let suffix = key.suffix(maskSuffixLength)
    return String(repeating: "*", count: starsCount) + suffix
}
