import Entities
import Foundation

public protocol DeviceStateDataSourceProtocol: Sendable {
    func subscribeToDeviceStates() async -> AsyncStream<[DeviceState]>
    func getDeviceState(deviceId: String) async throws -> DeviceState?
}

public actor DeviceStateDataSource: DeviceStateDataSourceProtocol {
    private let subscriptionManager: MQTTSubscriptionManagerProtocol
    private var deviceStatesCache: [String: DeviceState] = [:]

    public init(subscriptionManager: MQTTSubscriptionManagerProtocol) {
        self.subscriptionManager = subscriptionManager
    }

    public func subscribeToDeviceStates() -> AsyncStream<[DeviceState]> {
        AsyncStream { continuation in
            subscriptionManager.subscribe(to: "devices/+/status") { [weak self] message in
                guard let self else { return }

                let messageCopy = MQTTMessage(topic: message.topic, payload: message.payload)
                Task {
                    if let deviceState = self.parseDeviceStatusMessage(messageCopy) {
                        await self.updateDeviceState(deviceState)
                        continuation.yield([deviceState])
                    }
                }
            }

            subscriptionManager.subscribe(to: "devices/+/telemetry") { [weak self] message in
                guard let self else { return }

                let messageCopy = MQTTMessage(topic: message.topic, payload: message.payload)
                Task {
                    if let deviceState = self.parseDeviceTelemetryMessage(messageCopy) {
                        await self.updateDeviceState(deviceState)
                        continuation.yield([deviceState])
                    }
                }
            }
        }
    }

    public func getDeviceState(deviceId: String) -> DeviceState? {
        deviceStatesCache[deviceId]
    }

    private func updateDeviceState(_ deviceState: DeviceState) {
        deviceStatesCache[deviceState.deviceId] = deviceState
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

    private nonisolated func parseDeviceTelemetryMessage(_ message: MQTTMessage) -> DeviceState? {
        guard let data = message.payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        let deviceId = message.topic.components(separatedBy: "/")[1]

        return DeviceState(
            deviceId: deviceId,
            isOnline: true,
            battery: json["battery"] as? Int,
            temperature: json["temperature"] as? Double,
            lastUpdate: Date()
        )
    }

    private nonisolated func extractDeviceIdFromTopic(_ topic: String) -> String? {
        let components = topic.components(separatedBy: "/")
        guard components.count >= 3,
              components[0] == "devices",
              !components[1].isEmpty
        else {
            return nil
        }
        return components[1]
    }
}
