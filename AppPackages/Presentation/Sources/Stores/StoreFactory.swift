import ServiceProtocols
import UseCases

public protocol StoreFactory {
    @MainActor func makeDeviceStore() -> DeviceStore
}

public final class DefaultStoreFactory: StoreFactory {
    private let getManagedDevicesUseCase: GetManagedDevicesUseCase
    private let getDiscoveredDevicesUseCase: GetDiscoveredDevicesUseCase
    private let subscribeToStatesUseCase: SubscribeToDeviceStatesUseCase
    private let subscribeToDiscoveredDevicesUseCase: SubscribeToDiscoveredDevicesUseCase
    private let addDeviceUseCase: AddDeviceUseCase
    private let removeDeviceUseCase: RemoveDeviceUseCase
    private let sendDeviceCommandUseCase: SendDeviceCommandUseCase
    private let logger: LoggerProtocol

    public init(
        getManagedDevicesUseCase: GetManagedDevicesUseCase,
        getDiscoveredDevicesUseCase: GetDiscoveredDevicesUseCase,
        subscribeToStatesUseCase: SubscribeToDeviceStatesUseCase,
        subscribeToDiscoveredDevicesUseCase: SubscribeToDiscoveredDevicesUseCase,
        addDeviceUseCase: AddDeviceUseCase,
        removeDeviceUseCase: RemoveDeviceUseCase,
        sendDeviceCommandUseCase: SendDeviceCommandUseCase,
        logger: LoggerProtocol
    ) {
        self.getManagedDevicesUseCase = getManagedDevicesUseCase
        self.getDiscoveredDevicesUseCase = getDiscoveredDevicesUseCase
        self.subscribeToStatesUseCase = subscribeToStatesUseCase
        self.subscribeToDiscoveredDevicesUseCase =
            subscribeToDiscoveredDevicesUseCase
        self.addDeviceUseCase = addDeviceUseCase
        self.removeDeviceUseCase = removeDeviceUseCase
        self.sendDeviceCommandUseCase = sendDeviceCommandUseCase
        self.logger = logger
    }

    @MainActor public func makeDeviceStore() -> DeviceStore {
        DeviceStore(
            getManagedDevicesUseCase: getManagedDevicesUseCase,
            getDiscoveredDevicesUseCase: getDiscoveredDevicesUseCase,
            subscribeToStatesUseCase: subscribeToStatesUseCase,
            subscribeToDiscoveredDevicesUseCase: subscribeToDiscoveredDevicesUseCase,
            addDeviceUseCase: addDeviceUseCase,
            removeDeviceUseCase: removeDeviceUseCase,
            sendDeviceCommandUseCase: sendDeviceCommandUseCase,
            logger: logger
        )
    }
}
