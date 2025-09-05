@testable import DataSource
import DataUtilities
import Entities
import Foundation
import OSLog
import ServiceProtocols
import Testing

@Suite("DeviceStateDataSource Tests")
struct DeviceStateDataSourceTests {
    // MARK: - MQTT Message Parsing Tests

    @Test("Should parse valid temperature sensor MQTT message")
    func parseValidTemperatureSensorMessage() async throws {
        // Given
        let mockSubscriptionManager = MockMQTTSubscriptionManager()
        let mockLogger = MockLogger()
        let dataSource = DeviceStateDataSource(
            subscriptionManager: mockSubscriptionManager,
            logger: mockLogger
        )

        let temperaturePayload = """
        {
            "temperature": 22.5,
            "battery": 85,
            "timestamp": "2025-09-05T07:29:56.000000"
        }
        """

        let message = MQTTMessage(
            topic: "home/sensor/living_room_temp",
            payload: temperaturePayload
        )

        // When
        let deviceState = await dataSource.parseMessage(message)

        // Then
        #expect(deviceState != nil)
        #expect(deviceState?.deviceId == "living_room_temp")
        #expect(deviceState?.deviceType == .temperatureSensor)
        #expect(deviceState?.isOnline == true)
        #expect(deviceState?.temperatureSensor != nil)
        #expect(deviceState?.temperatureSensor?.temperature == 22.5)
        #expect(deviceState?.temperatureSensor?.battery == 85)
    }

    @Test("Should parse valid light state MQTT message")
    func parseValidLightStateMessage() async throws {
        // Given
        let mockSubscriptionManager = MockMQTTSubscriptionManager()
        let mockLogger = MockLogger()
        let dataSource = DeviceStateDataSource(
            subscriptionManager: mockSubscriptionManager,
            logger: mockLogger
        )

        let lightPayload = """
        {
            "state": "ON",
            "brightness": 75,
            "timestamp": "2025-09-05T07:29:56.000000"
        }
        """

        let message = MQTTMessage(
            topic: "home/light/kitchen_light",
            payload: lightPayload
        )

        // When
        let deviceState = await dataSource.parseMessage(message)

        // Then
        #expect(deviceState != nil)
        #expect(deviceState?.deviceId == "kitchen_light")
        #expect(deviceState?.deviceType == .smartLight)
        #expect(deviceState?.isOnline == true)
        #expect(deviceState?.lightState != nil)
        #expect(deviceState?.lightState?.brightness == 75)
    }

    @Test("Should handle invalid temperature sensor payload gracefully")
    func handleInvalidTemperatureSensorPayload() async throws {
        // Given
        let mockSubscriptionManager = MockMQTTSubscriptionManager()
        let mockLogger = MockLogger()
        let dataSource = DeviceStateDataSource(
            subscriptionManager: mockSubscriptionManager,
            logger: mockLogger
        )

        let invalidPayload = """
        {
            "invalid_field": "not_a_temperature",
            "wrong_type": true
        }
        """

        let message = MQTTMessage(
            topic: "home/sensor/broken_sensor",
            payload: invalidPayload
        )

        // When
        let deviceState = await dataSource.parseMessage(message)

        // Then
        #expect(deviceState != nil) // Device state should still be created
        #expect(deviceState?.deviceId == "broken_sensor")
        #expect(deviceState?.deviceType == .temperatureSensor)
        #expect(deviceState?.isOnline == true)
        #expect(deviceState?
            .temperatureSensor == nil
        ) // But sensor data should be nil

        // Logger may or may not log errors during decoding - that's acceptable
    }

    @Test("Should handle invalid light state payload gracefully")
    func handleInvalidLightStatePayload() async throws {
        // Given
        let mockSubscriptionManager = MockMQTTSubscriptionManager()
        let mockLogger = MockLogger()
        let dataSource = DeviceStateDataSource(
            subscriptionManager: mockSubscriptionManager,
            logger: mockLogger
        )

        let invalidPayload = """
        {
            "not_a_light_state": "invalid",
            "missing_required_fields": 123
        }
        """

        let message = MQTTMessage(
            topic: "home/light/broken_light",
            payload: invalidPayload
        )

        // When
        let deviceState = await dataSource.parseMessage(message)

        // Then
        #expect(deviceState != nil) // Device state should still be created
        #expect(deviceState?.deviceId == "broken_light")
        #expect(deviceState?.deviceType == .smartLight)
        #expect(deviceState?.isOnline == true)
        #expect(deviceState?.lightState == nil) // But light state should be nil
    }

    @Test("Should handle malformed JSON payload gracefully")
    func handleMalformedJsonPayload() async throws {
        // Given
        let mockSubscriptionManager = MockMQTTSubscriptionManager()
        let mockLogger = MockLogger()
        let dataSource = DeviceStateDataSource(
            subscriptionManager: mockSubscriptionManager,
            logger: mockLogger
        )

        let malformedPayload = "{ this is not valid json }"

        let message = MQTTMessage(
            topic: "home/sensor/malformed_sensor",
            payload: malformedPayload
        )

        // When
        let deviceState = await dataSource.parseMessage(message)

        // Then
        #expect(deviceState != nil) // Device state should still be created
        #expect(deviceState?.deviceId == "malformed_sensor")
        #expect(deviceState?.deviceType == .temperatureSensor)
        #expect(deviceState?.isOnline == true)
        #expect(deviceState?
            .temperatureSensor == nil
        ) // But sensor data should be nil

        // Logger may or may not log errors for malformed JSON - that's
        // acceptable
    }

    @Test("Should handle empty payload as offline device")
    func handleEmptyPayloadAsOffline() async throws {
        // Given
        let mockSubscriptionManager = MockMQTTSubscriptionManager()
        let mockLogger = MockLogger()
        let dataSource = DeviceStateDataSource(
            subscriptionManager: mockSubscriptionManager,
            logger: mockLogger
        )

        let message = MQTTMessage(
            topic: "home/sensor/offline_sensor",
            payload: ""
        )

        // When
        let deviceState = await dataSource.parseMessage(message)

        // Then
        #expect(deviceState != nil)
        #expect(deviceState?.deviceId == "offline_sensor")
        #expect(deviceState?.isOnline == false) // Empty payload means offline
        #expect(deviceState?.temperatureSensor == nil)
    }

    @Test("Should handle 'unavailable' payload as offline device")
    func handleUnavailablePayloadAsOffline() async throws {
        // Given
        let mockSubscriptionManager = MockMQTTSubscriptionManager()
        let mockLogger = MockLogger()
        let dataSource = DeviceStateDataSource(
            subscriptionManager: mockSubscriptionManager,
            logger: mockLogger
        )

        let message = MQTTMessage(
            topic: "home/light/unavailable_light",
            payload: "unavailable"
        )

        // When
        let deviceState = await dataSource.parseMessage(message)

        // Then
        #expect(deviceState != nil)
        #expect(deviceState?.deviceId == "unavailable_light")
        #expect(deviceState?.isOnline == false) // "unavailable" means offline
        #expect(deviceState?.lightState == nil)
    }

    @Test("Should handle unknown device types")
    func handleUnknownDeviceTypes() async throws {
        // Given
        let mockSubscriptionManager = MockMQTTSubscriptionManager()
        let mockLogger = MockLogger()
        let dataSource = DeviceStateDataSource(
            subscriptionManager: mockSubscriptionManager,
            logger: mockLogger
        )

        let message = MQTTMessage(
            topic: "home/unknown_type/mystery_device",
            payload: "some_payload"
        )

        // When
        let deviceState = await dataSource.parseMessage(message)

        // Then
        #expect(deviceState != nil)
        #expect(deviceState?.deviceId == "mystery_device")
        #expect(deviceState?.deviceType == .unknown)
        #expect(deviceState?.isOnline == true)
        #expect(deviceState?.temperatureSensor == nil)
        #expect(deviceState?.lightState == nil)
    }

    @Test("Should reject invalid topic patterns")
    func rejectInvalidTopicPatterns() async throws {
        // Given
        let mockSubscriptionManager = MockMQTTSubscriptionManager()
        let mockLogger = MockLogger()
        let dataSource = DeviceStateDataSource(
            subscriptionManager: mockSubscriptionManager,
            logger: mockLogger
        )

        let invalidTopics = [
            "invalid/topic", // Too few components
            "wrong/prefix/device", // Wrong prefix
            "not_home/sensor/device" // Wrong prefix
        ]

        for topic in invalidTopics {
            let message = MQTTMessage(topic: topic, payload: "test")

            // When
            let deviceState = await dataSource.parseMessage(message)

            // Then
            #expect(deviceState == nil, "Should reject topic: \(topic)")
        }
    }

    // MARK: - Device State Caching Tests

    @Test("Should cache and retrieve device states")
    func cacheAndRetrieveDeviceStates() async throws {
        // Given
        let mockSubscriptionManager = MockMQTTSubscriptionManager()
        let mockLogger = MockLogger()
        let dataSource = DeviceStateDataSource(
            subscriptionManager: mockSubscriptionManager,
            logger: mockLogger
        )

        let testDeviceId = "test_device"
        let message = MQTTMessage(
            topic: "home/sensor/\(testDeviceId)",
            payload: """
            {
                "temperature": 25.0,
                "battery": 90,
                "timestamp": "2025-09-05T07:29:56.000000"
            }
            """
        )

        // When - Parse message to cache device state
        let parsedState = await dataSource.parseMessage(message)
        #expect(parsedState != nil)

        // Then - Retrieve from cache
        let cachedStateResult = await dataSource
            .getDeviceState(deviceId: testDeviceId)

        switch cachedStateResult {
        case let .success(cachedState):
            #expect(cachedState != nil)
            #expect(cachedState?.deviceId == testDeviceId)
            #expect(cachedState?.temperatureSensor?.temperature == 25.0)
        case .failure:
            #expect(Bool(false), "Expected success but got failure")
        }
    }

    @Test("Should return nil for non-cached device")
    func returnNilForNonCachedDevice() async throws {
        // Given
        let mockSubscriptionManager = MockMQTTSubscriptionManager()
        let mockLogger = MockLogger()
        let dataSource = DeviceStateDataSource(
            subscriptionManager: mockSubscriptionManager,
            logger: mockLogger
        )

        // When
        let deviceStateResult = await dataSource
            .getDeviceState(deviceId: "nonexistent_device")

        // Then
        switch deviceStateResult {
        case let .success(deviceState):
            #expect(deviceState == nil)
        case .failure:
            #expect(
                Bool(false),
                "Expected success with nil value but got failure"
            )
        }
    }

    // MARK: - AsyncStream Subscription Tests

    @Test("Should create AsyncStream for device state subscription")
    func createAsyncStreamSubscription() async throws {
        // Given
        let mockSubscriptionManager = MockMQTTSubscriptionManager()
        let mockLogger = MockLogger()
        let dataSource = DeviceStateDataSource(
            subscriptionManager: mockSubscriptionManager,
            logger: mockLogger
        )

        let testTopic = "home/sensor/test_device"

        // When
        _ = await dataSource
            .subscribeToDeviceState(stateTopic: testTopic)

        // Then - Verify subscription was set up
        #expect(mockSubscriptionManager.subscribedTopics.contains(testTopic))

        // Simulate receiving a message
        let testMessage = MQTTMessage(
            topic: testTopic,
            payload: """
            {
                "temperature": 30.0,
                "battery": 95,
                "timestamp": "2025-09-05T07:29:56.000000"
            }
            """
        )

        await mockSubscriptionManager.simulateMessage(testMessage)

        // Note: Testing the actual stream behavior requires more complex async
        // testing
        // This test verifies the subscription setup
    }
}

// MARK: - Mock Dependencies

private final class MockMQTTSubscriptionManager: MQTTSubscriptionManagerProtocol,
    @unchecked Sendable {
    private var subscriptions: [String: @Sendable (MQTTMessage) -> Void] = [:]
    private let _subscribedTopics = NSMutableSet()

    var subscribedTopics: Set<String> {
        Set(_subscribedTopics.compactMap { $0 as? String })
    }

    func subscribe(
        to topic: String,
        handler: @escaping @Sendable (MQTTMessage) -> Void
    ) {
        subscriptions[topic] = handler
        _subscribedTopics.add(topic)
    }

    func unsubscribe(from topic: String) {
        subscriptions.removeValue(forKey: topic)
        _subscribedTopics.remove(topic)
    }

    func publish(topic _: String, payload _: String) async throws {
        // Mock implementation - no-op
    }

    func connect() async throws {
        // Mock implementation - no-op
    }

    func disconnect() {
        // Mock implementation - no-op
    }

    func simulateMessage(_ message: MQTTMessage) async {
        if let handler = subscriptions[message.topic] {
            handler(message)
        }
    }
}

private final class MockLogger: LoggerProtocol, @unchecked Sendable {
    private let _loggedMessages = NSMutableArray()

    var loggedMessages: [String] {
        _loggedMessages.compactMap { $0 as? String }
    }

    func log(_ message: String, level _: OSLogType) {
        _loggedMessages.add(message)
    }
}
