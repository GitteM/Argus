import Entities
import Observation

@MainActor
public protocol DeviceStoreProtocol: Observable {
    var viewState: DeviceViewState { get }
    var devices: [Device] { get }
    var discoveredDevices: [DiscoveredDevice] { get }
    var deviceStates: [String: DeviceState] { get }

    var selectedDevice: Device? { get }
    var selectedDeviceState: DeviceState? { get }

    func loadDashboardData()
    func subscribeToDevice(_ device: DiscoveredDevice)
    func unsubscribeFromDevice(withId deviceId: String)
    func sendCommand(to deviceId: String, command: Command)
    func selectDevice(_ device: Device)
    func clearSelection()
}
