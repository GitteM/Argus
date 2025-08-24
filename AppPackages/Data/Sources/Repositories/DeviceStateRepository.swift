import DataSource
import Entities
import RepositoryProtocols

public class DeviceStateRepository: DeviceStateRepositoryProtocol {
    private let mqttDataSource: MQTTDataSourceProtocol
    private let restDataSource: RESTDataSourceProtocol

    public init(
        mqttDataSource: MQTTDataSourceProtocol,
        restDataSource: RESTDataSourceProtocol
    ) {
        self.mqttDataSource = mqttDataSource
        self.restDataSource = restDataSource
    }

    /// First try to get current state via REST API
    public func getDeviceState(deviceId: String) async throws -> DeviceState {
        try await restDataSource.getDeviceState(deviceId: deviceId)
    }

    /// Subscribe to real-time device state updates via MQTT
    public func subscribeToDeviceStates() async throws -> AsyncStream<[DeviceState]> {
        await mqttDataSource.subscribeToDeviceStates()
    }
}
