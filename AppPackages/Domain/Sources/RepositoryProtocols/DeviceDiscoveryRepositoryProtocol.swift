import Entities

/**
 Finds new/unknown devices on the network that can potentially be added to the app.
  Finding new devices
 */
@available(macOS 10.15, iOS 13, *)
public protocol DeviceDiscoveryRepositoryProtocol {
    func getDiscoveredDevices() async -> Result<[DiscoveredDevice], AppError>
    func subscribeToDiscoveredDevices() async
        -> Result<AsyncStream<[DiscoveredDevice]>, AppError>
}
