import DataSource
import ServiceProtocols

public protocol DataSourceFactory {
    func makeDeviceDiscoveryDataSource() -> DeviceDiscoveryDataSourceProtocol
    func makeDeviceStateDataSource() -> DeviceStateDataSourceProtocol
    func makeDeviceCommandDataSource() -> DeviceCommandDataSourceProtocol
    func makeMQTTSubscriptionManager() -> MQTTSubscriptionManagerProtocol
}

public final class DefaultDataSourceFactory: DataSourceFactory {
    private let connectionManager: any MQTTConnectionManagerProtocol
    private let clientId: String

    public init(
        connectionManager: any MQTTConnectionManagerProtocol,
        clientId: String
    ) {
        self.connectionManager = connectionManager
        self.clientId = clientId
    }

    public func makeMQTTSubscriptionManager() -> MQTTSubscriptionManagerProtocol {
        MQTTSubscriptionManager(
            connectionManager: connectionManager
        )
    }

    public func makeDeviceDiscoveryDataSource() -> DeviceDiscoveryDataSourceProtocol {
        DeviceDiscoveryDataSource(
            subscriptionManager: makeMQTTSubscriptionManager(),
            clientId: clientId
        )
    }

    public func makeDeviceStateDataSource() -> DeviceStateDataSourceProtocol {
        DeviceStateDataSource(
            subscriptionManager: makeMQTTSubscriptionManager()
        )
    }

    public func makeDeviceCommandDataSource() -> DeviceCommandDataSourceProtocol {
        DeviceCommandDataSource(
            subscriptionManager: makeMQTTSubscriptionManager()
        )
    }
}
