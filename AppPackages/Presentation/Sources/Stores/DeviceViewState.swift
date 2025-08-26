import UseCases

public enum DeviceViewState {
    case loading
    case data(DeviceData)
    case error(String)
    case empty
}
