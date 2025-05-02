import Foundation

private let minTwo = 2
private let maxThree = 3
private let minFive = 5
private let maxSix = 6
private let minNine = 9
private let maxTen = 10

public enum SentenceCountRange: String, Codable, CaseIterable, Equatable {
    case twoToThree = "2-3"
    case fiveToSix = "5-6"
    case nineToTen = "9-10"

    public var min: Int {
        switch self {
        case .twoToThree: minTwo
        case .fiveToSix: minFive
        case .nineToTen: minNine
        }
    }

    public var max: Int {
        switch self {
        case .twoToThree: maxThree
        case .fiveToSix: maxSix
        case .nineToTen: maxTen
        }
    }
}
