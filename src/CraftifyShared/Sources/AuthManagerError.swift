import Foundation

public enum AuthManagerError: Error, Equatable {
    case accessDenied
    case invalidKey
    case itemNotFound
}
