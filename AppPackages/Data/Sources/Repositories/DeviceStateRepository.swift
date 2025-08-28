import DataSource
import Entities
import RepositoryProtocols

@available(macOS 10.15, iOS 13, *)
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

    @available(macOS 10.15, iOS 13, *)
    public func subscribeToDeviceState(stateTopic: String) async throws
        -> AsyncStream<DeviceState> {
        await deviceStateDataSource
            .subscribeToDeviceState(stateTopic: stateTopic)
    }
}
