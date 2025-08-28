import Entities

/**
 Purpose: Manages the current operational state/status of known devices.
 Single source of truth
 */

public protocol DeviceStateRepositoryProtocol {
    func getDeviceState(deviceId: String) async throws -> DeviceState?
    func subscribeToDeviceState(stateTopic: String) async throws
        -> AsyncStream<DeviceState>
}
