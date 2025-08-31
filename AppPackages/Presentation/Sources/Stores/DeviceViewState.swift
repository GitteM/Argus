import Entities

public enum DeviceViewState: Equatable {
    case loading
    case loaded
    case error(AppError)
    case empty

    /// Convenience computed property to get user-friendly error message
    public var errorMessage: String? {
        switch self {
        case let .error(appError):
            appError.errorDescription
        default:
            nil
        }
    }

    /// Convenience computed property to get recovery suggestion
    public var recoverySuggestion: String? {
        switch self {
        case let .error(appError):
            appError.recoverySuggestion
        default:
            nil
        }
    }
}
