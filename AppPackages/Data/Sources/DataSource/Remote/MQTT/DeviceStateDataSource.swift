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
            // Subscribe to Home Assistant state topics
            // Pattern: home/{component}/{device_id}/state
            subscriptionManager.subscribe(to: "home/+/+/state") { [weak self] message in
                guard let self else { return }

                let messageCopy = MQTTMessage(topic: message.topic, payload: message.payload)
                Task {
                    if let deviceState = self.parseHomeAssistantStateMessage(messageCopy) {
                        await self.updateDeviceState(deviceState)
                        continuation.yield([deviceState])
                    }
                }
            }

            // Also subscribe to sensor data topics which might be different
            // Pattern: home/sensor/{device_id}/temperature, etc.
            subscriptionManager.subscribe(to: "home/sensor/+/+") { [weak self] message in
                guard let self else { return }

                let messageCopy = MQTTMessage(topic: message.topic, payload: message.payload)
                Task {
                    if let deviceState = self.parseHomeAssistantSensorMessage(messageCopy) {
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

    private nonisolated func parseHomeAssistantStateMessage(
        _ message: MQTTMessage
    ) -> DeviceState? {
        // Parse Home Assistant state message
        // Topic format: home/{component}/{device_id}/state
        let topicComponents = message.topic.components(separatedBy: "/")
        guard topicComponents.count >= 4,
              topicComponents[0] == "home",
              topicComponents[3] == "state"
        else {
            return nil
        }

        let deviceId = topicComponents[2]
        let payload = message.payload

        // For most Home Assistant devices, the state is just a string value (ON/OFF, etc.)
        let isOnline = !payload.isEmpty && payload.lowercased() != "unavailable"

        return DeviceState(
            deviceId: deviceId,
            isOnline: isOnline,
            lastUpdate: Date()
        )
    }

    private nonisolated func parseHomeAssistantSensorMessage(
        _ message: MQTTMessage
    ) -> DeviceState? {
        // Parse Home Assistant sensor message
        // Topic format: home/sensor/{device_id}/{measurement_type}
        let topicComponents = message.topic.components(separatedBy: "/")
        guard topicComponents.count >= 4,
              topicComponents[0] == "home",
              topicComponents[1] == "sensor"
        else {
            return nil
        }

        let deviceId = topicComponents[2]
        let payload = message.payload

        return DeviceState(
            deviceId: deviceId,
            isOnline: !payload.isEmpty && payload.lowercased() != "unavailable",
            lastUpdate: Date()
        )
    }
}
