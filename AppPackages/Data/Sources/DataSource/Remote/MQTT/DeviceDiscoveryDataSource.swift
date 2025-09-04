import Entities
import Foundation
import ServiceProtocols

@available(macOS 10.15, iOS 13, *)
public protocol DeviceDiscoveryDataSourceProtocol: Sendable {
    func subscribeToDeviceDiscovery() async -> AsyncStream<[DiscoveredDevice]>
    func getDiscoveredDevices() async -> [DiscoveredDevice]
}

public actor DeviceDiscoveryDataSource: DeviceDiscoveryDataSourceProtocol {
    private let subscriptionManager: MQTTSubscriptionManagerProtocol
    private var discoveredDevicesCache: [DiscoveredDevice] = []
    private let clientId: String
    private let logger: LoggerProtocol

    public init(
        subscriptionManager: MQTTSubscriptionManagerProtocol,
        clientId: String,
        logger: LoggerProtocol
    ) {
        self.subscriptionManager = subscriptionManager
        self.clientId = clientId
        self.logger = logger
    }

    @available(macOS 10.15, iOS 13, *)
    public func subscribeToDeviceDiscovery()
        -> AsyncStream<[DiscoveredDevice]> {
        AsyncStream { continuation in
            Task { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }
                do {
                    // Ensure connection is established before subscribing
                    try await subscriptionManager.connect()

                    // Primary: Subscribe to Home Assistant MQTT Discovery config topics
                    // Pattern: homeassistant/{component}/{node_id}/config
                    let discoveryTopic = "homeassistant/+/+/config"

                    // Wrap subscription in error handling
                    subscriptionManager
                        .subscribe(to: discoveryTopic) { [weak self] message in
                            guard let self else { return }

                            let messageCopy = MQTTMessage(
                                topic: message.topic,
                                payload: message.payload
                            )
                            Task { [weak self] in
                                guard let self else { return }
                                do {
                                    if let discoveredDevice =
                                        try parseHomeAssistantConfigMessage(
                                            messageCopy
                                        ) {
                                        await addDiscoveredDevice(
                                            discoveredDevice
                                        )
                                        let devices =
                                            await getDiscoveredDevices()
                                        continuation.yield(devices)
                                    }
                                } catch {
                                    let errorDesc = error.localizedDescription
                                    logger.log(
                                        "Device discovery parsing error: \(errorDesc)",
                                        level: .error
                                    )
                                }
                            }
                        }

                } catch {
                    // Handle connection or subscription setup errors
                    let appError = wrapDiscoveryError(error)
                    let errorDesc = appError.errorDescription ?? "Unknown error"
                    logger.log(
                        "Device discovery subscription error: \(errorDesc)",
                        level: .error
                    )
                    // Note: AsyncStream doesn't support throwing during
                    // creation
                    // The stream will simply not yield any values if setup
                    // fails
                    continuation.finish()
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
    ) throws -> DiscoveredDevice? {
        // Parse Home Assistant MQTT Discovery config message
        // Topic format: homeassistant/{component}/{node_id}/config
        let topicComponents = message.topic.components(separatedBy: "/")

        // Validate topic format
        guard topicComponents.count >= 4 else {
            let count = topicComponents.count
            throw AppError.validationError(
                field: "topic",
                reason: "Invalid topic format: expected at least 4 components, got \(count)"
            )
        }

        guard topicComponents[0] == "homeassistant" else {
            let invalid = topicComponents[0]
            throw AppError.validationError(
                field: "topic",
                reason: "Invalid topic prefix: expected 'homeassistant', got '\(invalid)'"
            )
        }

        // Parse JSON payload
        guard let data = message.payload.data(using: .utf8) else {
            throw AppError.deserializationError(
                type: "MQTTMessage",
                details: "Failed to convert payload to UTF-8 data"
            )
        }

        guard let json = try? JSONSerialization
            .jsonObject(with: data) as? [String: Any] else {
            throw AppError.deserializationError(
                type: "JSON",
                details: "Failed to parse MQTT payload as JSON object"
            )
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

    /// Wraps errors that occur during device discovery with appropriate
    /// AppError types
    private nonisolated func wrapDiscoveryError(_ error: Error) -> AppError {
        // If it's already an AppError, return as-is
        if let appError = error as? AppError {
            return appError
        }

        // Handle common error patterns
        let errorDescription = error.localizedDescription.lowercased()

        if errorDescription.contains("connection") || errorDescription
            .contains("network") {
            return .mqttConnectionFailed(
                "Device discovery connection failed: \(error.localizedDescription)"
            )
        } else if errorDescription.contains("timeout") {
            return .discoveryTimeout
        } else if errorDescription.contains("subscription") {
            return .mqttSubscriptionFailed(topic: "homeassistant/+/+/config")
        } else {
            return .discoveryFailed(reason: error.localizedDescription)
        }
    }
}
