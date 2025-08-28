public enum DeviceViewState: Equatable {
    case loading
    case loaded
    case error(String)
    case empty
}
