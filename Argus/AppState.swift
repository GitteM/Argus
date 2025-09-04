import Entities

public enum AppState: Equatable {
    case initializing
    case loading
    case ready
    case error(AppError)
    case disconnected

    // Convenience computed properties
    public var errorMessage: String? {
        switch self {
        case let .error(appError):
            appError.errorDescription
        default:
            nil
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case let .error(appError):
            appError.recoverySuggestion
        default:
            nil
        }
    }

    public var canNavigate: Bool {
        switch self {
        case .ready:
            true
        default:
            false
        }
    }
}
