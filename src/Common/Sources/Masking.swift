import Foundation

private let maskMinKeyLength = 8
private let maskSuffixLength = 4
private let maskPrefixLength = 3

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

/// Короткая маска для отображения на экране настроек: «sk-…7890»
@inline(__always)
public func shortMaskKey(_ key: String?) -> String {
    guard let key, key.count > maskMinKeyLength else {
        return String(repeating: "*", count: maskMinKeyLength)
    }
    return "\(key.prefix(maskPrefixLength))…\(key.suffix(maskSuffixLength))"
}
