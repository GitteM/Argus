import CocoaMQTT
import Entities
import Foundation
import RepositoryProtocols
import UIKit

public protocol MQTTDataSourceProtocol: Sendable {
    // Device Discovery
    func startDeviceDiscovery() async throws
    func stopDeviceDiscovery() async throws
    func subscribeToDeviceDiscovery() async -> AsyncStream<[DiscoveredDevice]>

    // Device States
    func subscribeToDeviceStates() async -> AsyncStream<[DeviceState]>

    // Device Commands
    func sendDeviceCommand(deviceId: String, command: Command) async throws
}

public actor MQTTDataSource: MQTTDataSourceProtocol {
    private let connectionManager: MQTTConnectionManager
    private var discoveredDevicesCache: [DiscoveredDevice] = []
    private let clientId: String

    public init(
        connectionManager: MQTTConnectionManager,
        clientId: String
    ) {
        self.connectionManager = connectionManager
        self.clientId = clientId
    }

    // MARK: - Device Discovery

    public func startDeviceDiscovery() async throws {
        // Publish to discovery control topic
        try await connectionManager.publish(
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
        try await connectionManager.publish(
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
            // Subscribe to device discovery announcements
            connectionManager.subscribe(to: "discovery/devices/+/announce") { [weak self] message in
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

            // Also subscribe to device removal announcements
            connectionManager.subscribe(to: "discovery/devices/+/leave") { [weak self] message in
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

    // MARK: - Device States

    public func subscribeToDeviceStates() -> AsyncStream<[DeviceState]> {
        AsyncStream { continuation in
            // Subscribe to all device status updates
            connectionManager.subscribe(to: "devices/+/status") { [weak self] message in
                guard let self else { return }

                let messageCopy = MQTTMessage(topic: message.topic, payload: message.payload)
                Task {
                    if let deviceState = self.parseDeviceStatusMessage(messageCopy) {
                        continuation.yield([deviceState])
                    }
                }
            }

            // Subscribe to device telemetry for richer state info
            connectionManager.subscribe(to: "devices/+/telemetry") { [weak self] message in
                guard let self else { return }

                let messageCopy = MQTTMessage(topic: message.topic, payload: message.payload)
                Task {
                    if let deviceState = self.parseDeviceTelemetryMessage(messageCopy) {
                        continuation.yield([deviceState])
                    }
                }
            }
        }
    }

    // MARK: - Device Commands

    public func sendDeviceCommand(deviceId: String, command: Command) async throws {
        let topic = "devices/\(deviceId)/commands"
        let payload = try JSONEncoder().encode(command)
        try await connectionManager.publish(topic: topic, payload: String(data: payload, encoding: .utf8) ?? "")
    }

    // MARK: - Actor-Isolated Cache Management

    private func addDiscoveredDevice(_ device: DiscoveredDevice) {
        // Add to cache if not already present
        if !discoveredDevicesCache.contains(where: { $0.id == device.id }) {
            discoveredDevicesCache.append(device)
        }

        // Clean up old discoveries (older than 5 minutes)
        discoveredDevicesCache.removeAll {
            Date().timeIntervalSince($0.discoveredAt) > 300
        }
    }

    private func removeDiscoveredDevice(_ deviceId: String) {
        discoveredDevicesCache.removeAll { $0.id == deviceId }
    }

    private func getDiscoveredDevices() -> [DiscoveredDevice] {
        discoveredDevicesCache
    }

    // MARK: - Message Parsing

    private nonisolated func parseDiscoveredDeviceMessage(_ message: MQTTMessage) -> DiscoveredDevice? {
        guard let data = message.payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        guard let deviceId = json["deviceId"] as? String,
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
            isAlreadyAdded: false // Will be determined by repository
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

    private nonisolated func parseDeviceStatusMessage(_ message: MQTTMessage) -> DeviceState? {
        guard let data = message.payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let deviceId = extractDeviceIdFromTopic(message.topic),
              let isOnline = json["online"] as? Bool
        else {
            return nil
        }

        return DeviceState(
            deviceId: deviceId,
            isOnline: isOnline,
            battery: json["battery"] as? Int,
            temperature: json["temperature"] as? Double,
            lastUpdate: Date()
        )
    }

    // Add this helper method to MQTTDataSource
    private nonisolated func extractDeviceIdFromTopic(_ topic: String) -> String? {
        let components = topic.components(separatedBy: "/")

        // Expected format: "devices/{deviceId}/status" or "devices/{deviceId}/telemetry"
        guard components.count >= 3,
              components[0] == "devices",
              !components[1].isEmpty
        else {
            return nil
        }

        return components[1]
    }

    private nonisolated func parseDeviceTelemetryMessage(_ message: MQTTMessage) -> DeviceState? {
        guard let data = message.payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        let deviceId = message.topic.components(separatedBy: "/")[1]

        return DeviceState(
            deviceId: deviceId,
            isOnline: true, // If sending telemetry, assume online
            battery: json["battery"] as? Int,
            temperature: json["temperature"] as? Double,
            lastUpdate: Date()
        )
    }
}
