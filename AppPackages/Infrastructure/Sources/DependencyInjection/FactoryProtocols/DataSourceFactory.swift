import DataSource
import ServiceProtocols

public protocol DataSourceFactory {
    func makeDeviceDiscoveryDataSource() -> DeviceDiscoveryDataSourceProtocol
    func makeDeviceStateDataSource() -> DeviceStateDataSourceProtocol
    func makeDeviceCommandDataSource() -> DeviceCommandDataSourceProtocol
    func makeMQTTSubscriptionManager() -> MQTTSubscriptionManagerProtocol
    func makeMQTTConnectionManager() -> any MQTTConnectionManagerProtocol
}

public final class DefaultDataSourceFactory: DataSourceFactory {
    private let logger: LoggerProtocol
    private let mqttBroker: String
    private let mqttPort: UInt16
    private let clientId: String

    public init(
        logger: LoggerProtocol,
        mqttBroker: String,
        mqttPort: UInt16,
        clientId: String
    ) {
        self.logger = logger
        self.mqttBroker = mqttBroker
        self.mqttPort = mqttPort
        self.clientId = clientId
    }

    public func makeMQTTConnectionManager() -> any MQTTConnectionManagerProtocol {
        MQTTConnectionManager(
            clientId: clientId,
            broker: mqttBroker,
            port: mqttPort,
            logger: logger
        )
    }

    public func makeMQTTSubscriptionManager() -> MQTTSubscriptionManagerProtocol {
        MQTTSubscriptionManager(
            connectionManager: makeMQTTConnectionManager()
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
