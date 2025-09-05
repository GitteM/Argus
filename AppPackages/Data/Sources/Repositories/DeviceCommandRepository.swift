import DataSource
import Entities
import RepositoryProtocols

public struct DeviceCommandRepository: DeviceCommandRepositoryProtocol {
    private let deviceCommandDataSource: DeviceCommandDataSourceProtocol

    public init(deviceCommandDataSource: DeviceCommandDataSourceProtocol) {
        self.deviceCommandDataSource = deviceCommandDataSource
    }

    public func sendDeviceCommand(
        deviceId: String,
        command: Command
    ) async -> Result<Void, AppError> {
        await deviceCommandDataSource.sendDeviceCommand(
            deviceId: deviceId,
            command: command
        )
    }
}
