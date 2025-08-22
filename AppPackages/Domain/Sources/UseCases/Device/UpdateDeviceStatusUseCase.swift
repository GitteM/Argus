import Entities

public typealias DeviceResult = Result<Device, Error>

public protocol UpdateDeviceStatusUseCase {
    func execute(_ deviceStatus: DeviceStatus) async throws -> DeviceResult
}
