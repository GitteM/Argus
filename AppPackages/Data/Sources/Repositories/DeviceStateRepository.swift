import DataSource
import Entities
import RepositoryProtocols

public class DeviceStateRepository: DeviceStateRepositoryProtocol {
    private let deviceStateDataSource: DeviceStateDataSourceProtocol

    public init(
        deviceStateDataSource: DeviceStateDataSourceProtocol
    ) {
        self.deviceStateDataSource = deviceStateDataSource
    }

    public func getDeviceState(deviceId: String) async throws -> DeviceState? {
        try await deviceStateDataSource.getDeviceState(deviceId: deviceId)
    }

    /// Subscribe to real-time device state updates via MQTT
    public func subscribeToDeviceStates() async throws -> AsyncStream<[DeviceState]> {
        await deviceStateDataSource.subscribeToDeviceStates()
    }
}
