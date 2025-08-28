import Entities
import Foundation
import Observation

// TODO: For testing purposes
@MainActor
@Observable
public final class MockDeviceStore: DeviceStoreProtocol {
    public var viewState: DeviceViewState = .loaded
    public var devices: [Device] = []
    public var discoveredDevices: [DiscoveredDevice] = []
    public var deviceStates: [String: DeviceState] = [:]
    public var selectedDevice: Device?

    public init() {}

    public func loadDashboardData() {
        // Mock implementation - do nothing
    }

    public func subscribeToDevice(_: DiscoveredDevice) {
        // Mock implementation - do nothing
    }

    public func unsubscribeFromDevice(withId _: String) {
        // Mock implementation - do nothing
    }

    public func sendCommand(to _: String, command _: Command) {
        // Mock implementation - do nothing
    }

    public func selectDevice(_ device: Device) {
        selectedDevice = device
    }

    public func clearSelection() {
        selectedDevice = nil
    }

    // Convenience factory methods
    public static func withDevices() -> MockDeviceStore {
        let store = MockDeviceStore()
        store.devices = Device.mockDefaults
        store.discoveredDevices = DiscoveredDevice.mockDefaults
        return store
    }

    public static func empty() -> MockDeviceStore {
        MockDeviceStore()
    }
}
