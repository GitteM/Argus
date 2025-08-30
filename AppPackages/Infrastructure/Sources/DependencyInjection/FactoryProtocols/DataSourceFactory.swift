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
    private let logger: LoggerProtocol

    public init(
        connectionManager: any MQTTConnectionManagerProtocol,
        clientId: String,
        logger: LoggerProtocol
    ) {
        self.connectionManager = connectionManager
        self.clientId = clientId
        self.logger = logger
    }

    public func makeMQTTSubscriptionManager()
        -> MQTTSubscriptionManagerProtocol {
        MQTTSubscriptionManager(
            connectionManager: connectionManager
        )
    }

    public func makeDeviceDiscoveryDataSource()
        -> DeviceDiscoveryDataSourceProtocol {
        DeviceDiscoveryDataSource(
            subscriptionManager: makeMQTTSubscriptionManager(),
            clientId: clientId,
            logger: logger
        )
    }

    public func makeDeviceStateDataSource() -> DeviceStateDataSourceProtocol {
        DeviceStateDataSource(
            subscriptionManager: makeMQTTSubscriptionManager(),
            logger: logger
        )
    }

    public func makeDeviceCommandDataSource()
        -> DeviceCommandDataSourceProtocol {
        DeviceCommandDataSource(
            subscriptionManager: makeMQTTSubscriptionManager()
        )
    }
}
