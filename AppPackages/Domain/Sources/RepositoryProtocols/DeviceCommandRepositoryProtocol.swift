import Entities

public protocol DeviceCommandRepositoryProtocol {
    func sendDeviceCommand(deviceId: String, command: Command) async throws
}
