import Entities

/**
 Finds new/unknown devices on the network that can potentially be added to the app.
  Finding new devices
 */
public protocol DeviceDiscoveryRepositoryProtocol {
    func startDiscovery() async throws
    func stopDiscovery() async throws
    func getDiscoveredDevices() async throws -> [DiscoveredDevice]
    func subscribeToDiscoveredDevices() async throws -> AsyncStream<[DiscoveredDevice]>
}
