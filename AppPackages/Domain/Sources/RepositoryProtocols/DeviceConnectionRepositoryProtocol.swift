import Entities
import Foundation

/**
 Manages the MQTT communication layer between the app and individual devices.
 */

public protocol DeviceConnectionRepositoryProtocol {
    func addDevice(_ discoveredDevice: DiscoveredDevice) async
        -> Result<Device, AppError>
    func removeDevice(deviceId: String) async -> Result<Void, AppError>
    func getManagedDevices() async -> Result<[Device], AppError>
}
