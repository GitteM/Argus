import ServiceProtocols
import Stores
import UseCases

protocol StoreFactory {
    @MainActor func makeDeviceStore() -> DeviceStore
}

final class DefaultStoreFactory: StoreFactory {
    private let getManagedDevicesUseCase: GetManagedDevicesUseCase
    private let getDiscoveredDevicesUseCase: GetDiscoveredDevicesUseCase
    private let startDiscoveryUseCase: StartDeviceDiscoveryUseCase
    private let stopDiscoveryUseCase: StopDeviceDiscoveryUseCase
    private let subscribeToStatesUseCase: SubscribeToDeviceStatesUseCase
    private let subscribeToDiscoveredDevicesUseCase: SubscribeToDiscoveredDevicesUseCase
    private let addDeviceUseCase: AddDeviceUseCase
    private let sendDeviceCommandUseCase: SendDeviceCommandUseCase
    private let logger: LoggerProtocol

    init(
        getManagedDevicesUseCase: GetManagedDevicesUseCase,
        getDiscoveredDevicesUseCase: GetDiscoveredDevicesUseCase,
        startDiscoveryUseCase: StartDeviceDiscoveryUseCase,
        stopDiscoveryUseCase: StopDeviceDiscoveryUseCase,
        subscribeToStatesUseCase: SubscribeToDeviceStatesUseCase,
        subscribeToDiscoveredDevicesUseCase: SubscribeToDiscoveredDevicesUseCase,
        addDeviceUseCase: AddDeviceUseCase,
        sendDeviceCommandUseCase: SendDeviceCommandUseCase,
        logger: LoggerProtocol
    ) {
        self.getManagedDevicesUseCase = getManagedDevicesUseCase
        self.getDiscoveredDevicesUseCase = getDiscoveredDevicesUseCase
        self.startDiscoveryUseCase = startDiscoveryUseCase
        self.stopDiscoveryUseCase = stopDiscoveryUseCase
        self.subscribeToStatesUseCase = subscribeToStatesUseCase
        self.subscribeToDiscoveredDevicesUseCase = subscribeToDiscoveredDevicesUseCase
        self.addDeviceUseCase = addDeviceUseCase
        self.sendDeviceCommandUseCase = sendDeviceCommandUseCase
        self.logger = logger
    }

    @MainActor func makeDeviceStore() -> DeviceStore {
        DeviceStore(
            getManagedDevicesUseCase: getManagedDevicesUseCase,
            getDiscoveredDevicesUseCase: getDiscoveredDevicesUseCase,
            startDiscoveryUseCase: startDiscoveryUseCase,
            stopDiscoveryUseCase: stopDiscoveryUseCase,
            subscribeToStatesUseCase: subscribeToStatesUseCase,
            subscribeToDiscoveredDevicesUseCase: subscribeToDiscoveredDevicesUseCase,
            addDeviceUseCase: addDeviceUseCase,
            sendDeviceCommandUseCase: sendDeviceCommandUseCase,
            logger: logger
        )
    }
}
