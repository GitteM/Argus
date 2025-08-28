import Entities
import Foundation
import ServiceProtocols

public protocol DeviceDiscoveryDataSourceProtocol: Sendable {
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

    public func subscribeToDeviceDiscovery()
        -> AsyncStream<[DiscoveredDevice]> {
        AsyncStream { continuation in
            // Primary: Subscribe to Home Assistant MQTT Discovery config topics
            // Pattern: homeassistant/{component}/{node_id}/config
            let discoveryTopic = "homeassistant/+/+/config"
            subscriptionManager
                .subscribe(to: discoveryTopic) { [weak self] message in
                    guard let self else { return }

                    let messageCopy = MQTTMessage(
                        topic: message.topic,
                        payload: message.payload
                    )
                    Task {
                        if let discoveredDevice = self
                            .parseHomeAssistantConfigMessage(messageCopy) {
                            await self.addDiscoveredDevice(discoveredDevice)
                            let devices = await self.getDiscoveredDevices()
                            continuation.yield(devices)
                        }
                    }
                }
        }
    }

    public func getDiscoveredDevices() async -> [DiscoveredDevice] {
        // Return real discovered devices from cache
        // Clean up expired devices (older than 5 minutes) before returning
        cleanupExpiredDevices()
        return discoveredDevicesCache
    }

    private func addDiscoveredDevice(_ device: DiscoveredDevice) {
        // Update existing device or add new one
        if let existingIndex = discoveredDevicesCache
            .firstIndex(where: { $0.id == device.id }) {
            discoveredDevicesCache[existingIndex] = device
        } else {
            discoveredDevicesCache.append(device)
        }

        cleanupExpiredDevices()
    }

    private func cleanupExpiredDevices() {
        discoveredDevicesCache.removeAll {
            Date().timeIntervalSince($0.discoveredAt) > 300
        }
    }

    private func removeDiscoveredDevice(_ deviceId: String) {
        discoveredDevicesCache.removeAll { $0.id == deviceId }
    }

    private nonisolated func parseHomeAssistantConfigMessage(
        _ message: MQTTMessage
    ) -> DiscoveredDevice? {
        // Parse Home Assistant MQTT Discovery config message
        // Topic format: homeassistant/{component}/{node_id}/config
        let topicComponents = message.topic.components(separatedBy: "/")
        guard topicComponents.count >= 4,
              topicComponents[0] == "homeassistant",
              let data = message.payload.data(using: .utf8),
              let json = try? JSONSerialization
              .jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        let component = topicComponents[1] // light, sensor, etc.
        let nodeId = topicComponents[2] // device identifier

        // Extract device information from the config
        let deviceName = json["name"] as? String ?? "Unknown Device"
        let deviceInfo = json["device"] as? [String: Any]
        let manufacturer = deviceInfo?["manufacturer"] as? String ?? "Unknown"
        let model = deviceInfo?["model"] as? String ?? "Unknown"

        let unitOfMeasurement = json["unit_of_measurement"] as? String
        let supportsBrightness = json["brightness"] as? Bool ?? false
        let stateTopic = json["state_topic"] as? String ?? ""
        let commandTopic = json["command_topic"] as? String ?? ""

        // Use device identifiers if available, otherwise fall back to node_id
        let deviceId: String =
            if let identifiers = deviceInfo?["identifiers"] as? [String],
            let firstIdentifier = identifiers.first {
                firstIdentifier
            } else {
                nodeId
            }

        // Map Home Assistant component types to our DeviceType enum
        let deviceType = mapComponentToDeviceType(component)

        return DiscoveredDevice(
            id: deviceId,
            name: deviceName,
            type: deviceType,
            manufacturer: manufacturer,
            model: model,
            unitOfMeasurement: unitOfMeasurement,
            supportsBrightness: supportsBrightness,
            discoveredAt: Date(),
            isAlreadyAdded: false,
            commandTopic: commandTopic,
            stateTopic: stateTopic
        )
    }

    private nonisolated func mapComponentToDeviceType(_ component: String)
        -> DeviceType {
        switch component.lowercased() {
        case "light":
            .smartLight
        case "sensor":
            .temperatureSensor // Default sensor type, could be refined further
        default:
            .unknown
        }
    }
}
