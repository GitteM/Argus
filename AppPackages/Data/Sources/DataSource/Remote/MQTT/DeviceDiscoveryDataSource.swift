import Entities
import Foundation

public protocol DeviceDiscoveryDataSourceProtocol: Sendable {
    func startDeviceDiscovery() async throws
    func stopDeviceDiscovery() async throws
    func subscribeToDeviceDiscovery() async -> AsyncStream<[DiscoveredDevice]>
    func getDiscoveredDevices() async -> [DiscoveredDevice]
}

public actor DeviceDiscoveryDataSource: DeviceDiscoveryDataSourceProtocol {
    private let subscriptionManager: MQTTSubscriptionManagerProtocol
    private var discoveredDevicesCache: [DiscoveredDevice] = []
    private let clientId: String

    public init(
        subscriptionManager: MQTTSubscriptionManagerProtocol,
        clientId: String
    ) {
        self.subscriptionManager = subscriptionManager
        self.clientId = clientId
    }

    public func startDeviceDiscovery() async throws {
        try await subscriptionManager.publish(
            topic: "system/discovery/start",
            payload: """
            {
                "clientId": "\(clientId)",
                "timestamp": "\(ISO8601DateFormatter().string(from: Date()))"
            }
            """
        )
    }

    public func stopDeviceDiscovery() async throws {
        try await subscriptionManager.publish(
            topic: "system/discovery/stop",
            payload: """
            {
                "clientId": "\(clientId)"
            }
            """
        )
    }

    public func subscribeToDeviceDiscovery() -> AsyncStream<[DiscoveredDevice]> {
        AsyncStream { continuation in
            let announce = "discovery/devices/+/announce"
            subscriptionManager.subscribe(to: announce) { [weak self] message in
                guard let self else { return }

                let messageCopy = MQTTMessage(topic: message.topic, payload: message.payload)
                Task {
                    if let discoveredDevice = self.parseDiscoveredDeviceMessage(messageCopy) {
                        await self.addDiscoveredDevice(discoveredDevice)
                        let devices = await self.getDiscoveredDevices()
                        continuation.yield(devices)
                    }
                }
            }

            let leave = "discovery/devices/+/leave"
            subscriptionManager.subscribe(to: leave) { [weak self] message in
                guard let self else { return }

                let messageCopy = MQTTMessage(topic: message.topic, payload: message.payload)
                Task {
                    if let deviceId = self.parseDeviceLeaveMessage(messageCopy) {
                        await self.removeDiscoveredDevice(deviceId)
                        let devices = await self.getDiscoveredDevices()
                        continuation.yield(devices)
                    }
                }
            }
        }
    }

    public func getDiscoveredDevices() -> [DiscoveredDevice] {
        if discoveredDevicesCache.isEmpty {
            return DiscoveredDevice.mockDefaults
        }
        return discoveredDevicesCache
    }

    private func addDiscoveredDevice(_ device: DiscoveredDevice) {
        if !discoveredDevicesCache.contains(where: { $0.id == device.id }) {
            discoveredDevicesCache.append(device)
        }

        discoveredDevicesCache.removeAll {
            Date().timeIntervalSince($0.discoveredAt) > 300
        }
    }

    private func removeDiscoveredDevice(_ deviceId: String) {
        discoveredDevicesCache.removeAll { $0.id == deviceId }
    }

    private nonisolated func parseDiscoveredDeviceMessage(
        _ message: MQTTMessage
    ) -> DiscoveredDevice? {
        guard let data = message.payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let deviceId = json["deviceId"] as? String,
              let deviceName = json["name"] as? String,
              let deviceType = json["type"] as? String,
              let signalStrength = json["signalStrength"] as? Int
        else {
            return nil
        }

        return DiscoveredDevice(
            id: deviceId,
            name: deviceName,
            type: DeviceType(rawValue: deviceType) ?? .unknown,
            signalStrength: signalStrength,
            discoveredAt: Date(),
            isAlreadyAdded: false
        )
    }

    private nonisolated func parseDeviceLeaveMessage(_ message: MQTTMessage) -> String? {
        guard let data = message.payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let deviceId = json["deviceId"] as? String
        else {
            return nil
        }
        return deviceId
    }
}
