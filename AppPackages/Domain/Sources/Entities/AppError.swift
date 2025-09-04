import Foundation

public enum AppError: Error, LocalizedError {
    // MARK: - Connection Errors

    case mqttConnectionFailed(String? = nil)
    case mqttNotConnected
    case mqttPublishFailed(topic: String)
    case mqttSubscriptionFailed(topic: String)

    // MARK: - Device Errors

    case deviceNotFound(deviceId: String)
    case deviceAlreadyExists(deviceId: String)
    case deviceConnectionFailed(deviceId: String)
    case deviceCommandFailed(deviceId: String, command: String)
    case invalidDeviceConfiguration(reason: String)

    // MARK: - Data Errors

    case persistenceError(operation: String, details: String? = nil)
    case cacheError(key: String, operation: String)
    case serializationError(type: String, details: String? = nil)
    case deserializationError(type: String, details: String? = nil)
    case validationError(field: String, reason: String)

    // MARK: - Discovery Errors

    case discoveryFailed(reason: String? = nil)
    case discoveryTimeout
    case noDevicesDiscovered

    // MARK: - System Errors

    case fileSystemError(operation: String, path: String? = nil)
    case configurationError(component: String, reason: String)
    case serviceUnavailable(service: String)
    case timeout(operation: String, duration: TimeInterval? = nil)

    // MARK: - Unknown Errors

    case unknown(underlying: Error? = nil)

    // MARK: - App Init Errors

    case initializationError(component: String, reason: String)
}

// MARK: - LocalizedError Implementation

public extension AppError {
    var errorDescription: String? {
        switch self {
        // MARK: Connection Errors

        case let .mqttConnectionFailed(details):
            if let details {
                return "Failed to connect to MQTT broker: \(details)"
            }
            return "Failed to connect to MQTT broker"
        case .mqttNotConnected:
            return "MQTT broker is not connected"
        case let .mqttPublishFailed(topic):
            return "Failed to publish message to topic '\(topic)'"
        case let .mqttSubscriptionFailed(topic):
            return "Failed to subscribe to topic '\(topic)'"

        // MARK: Device Errors
        case let .deviceNotFound(deviceId):
            return "Device '\(deviceId)' was not found"
        case let .deviceAlreadyExists(deviceId):
            return "Device '\(deviceId)' already exists"
        case let .deviceConnectionFailed(deviceId):
            return "Failed to connect to device '\(deviceId)'"
        case let .deviceCommandFailed(deviceId, command):
            return "Failed to execute command '\(command)' on device '\(deviceId)'"
        case let .invalidDeviceConfiguration(reason):
            return "Invalid device configuration: \(reason)"

        // MARK: Data Errors
        case let .persistenceError(operation, details):
            if let details {
                return "Persistence error during '\(operation)': \(details)"
            }
            return "Persistence error during '\(operation)'"
        case let .cacheError(key, operation):
            return "Cache error for key '\(key)' during '\(operation)'"
        case let .serializationError(type, details):
            if let details {
                return "Failed to serialize '\(type)': \(details)"
            }
            return "Failed to serialize '\(type)'"
        case let .deserializationError(type, details):
            if let details {
                return "Failed to deserialize '\(type)': \(details)"
            }
            return "Failed to deserialize '\(type)'"
        case let .validationError(field, reason):
            return "Validation error for field '\(field)': \(reason)"

        // MARK: Discovery Errors
        case let .discoveryFailed(reason):
            if let reason {
                return "Device discovery failed: \(reason)"
            }
            return "Device discovery failed"
        case .discoveryTimeout:
            return "Device discovery timed out"
        case .noDevicesDiscovered:
            return "No devices were discovered"

        // MARK: System Errors
        case let .fileSystemError(operation, path):
            if let path {
                return "File system error during '\(operation)' at path '\(path)'"
            }
            return "File system error during '\(operation)'"
        case let .configurationError(component, reason):
            return "Configuration error for '\(component)': \(reason)"
        case let .serviceUnavailable(service):
            return "Service '\(service)' is currently unavailable"
        case let .timeout(operation, duration):
            if let duration {
                return "Operation '\(operation)' timed out after \(duration) seconds"
            }
            return "Operation '\(operation)' timed out"

        // MARK: App Initialization Errors
        case let .initializationError(component, reason):
            return "Initialization error for '\(component)': \(reason)"

        // MARK: Unknown Errors
        case let .unknown(underlying):
            if let underlying {
                return "An unexpected error occurred: \(underlying.localizedDescription)"
            }
            return "An unexpected error occurred"
        }
    }

    var failureReason: String? {
        switch self {
        case let .mqttConnectionFailed(details):
            details ?? "Network or broker configuration issue"
        case .mqttNotConnected:
            "Connection to MQTT broker was lost or never established"
        case .deviceNotFound:
            "Device may have been removed or is offline"
        case .deviceAlreadyExists:
            "Cannot add duplicate device"
        case .discoveryTimeout:
            "Network discovery took too long to complete"
        default:
            nil
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .mqttNotConnected:
            return "Try reconnecting to the MQTT broker"
        case .deviceNotFound:
            return "Ensure the device is powered on and connected to the network"
        case .deviceAlreadyExists:
            return "Use a different device ID or remove the existing device first"
        case .discoveryTimeout, .noDevicesDiscovered:
            return "Ensure devices are powered on and in discovery mode"
        case let .persistenceError(operation, _):
            if operation.contains("write") || operation.contains("save") {
                return "Try freeing up storage space or restarting the app"
            }
            return "Try restarting the app"
        case .serviceUnavailable:
            return "Wait a moment and try again"
        default:
            return "Try restarting the app or contact support if the problem persists"
        }
    }
}

// MARK: - Error Category

public extension AppError {
    /// Categorizes errors for analytics and debugging purposes
    var category: ErrorCategory {
        switch self {
        case .mqttConnectionFailed, .mqttNotConnected, .mqttPublishFailed,
             .mqttSubscriptionFailed:
            .connectivity
        case .deviceNotFound, .deviceAlreadyExists, .deviceConnectionFailed,
             .deviceCommandFailed, .invalidDeviceConfiguration:
            .device
        case .persistenceError, .cacheError, .serializationError,
             .deserializationError, .validationError:
            .data
        case .discoveryFailed, .discoveryTimeout, .noDevicesDiscovered:
            .discovery
        case .fileSystemError, .configurationError, .serviceUnavailable,
             .timeout:
            .system
        case .initializationError:
            .initialization
        case .unknown:
            .unknown
        }
    }

    /// Indicates if this error is recoverable through user action
    var isRecoverable: Bool {
        switch self {
        case .mqttConnectionFailed, .mqttNotConnected,
             .deviceConnectionFailed, .discoveryTimeout, .serviceUnavailable:
            true
        case .deviceNotFound, .deviceAlreadyExists:
            true
        case .invalidDeviceConfiguration, .validationError:
            true
        case .serializationError, .deserializationError, .configurationError:
            false
        default:
            true // Assume recoverable unless proven otherwise
        }
    }

    /// Indicates if this error should be reported for analytics/debugging
    var shouldReport: Bool {
        switch self {
        case .deviceNotFound, .deviceAlreadyExists:
            false // Expected user errors
        case .validationError:
            false // Input validation errors
        case .unknown, .serializationError, .deserializationError,
             .configurationError:
            true // Unexpected errors that need investigation
        default:
            true
        }
    }
}

// MARK: - Error Category Enum

public enum ErrorCategory: String, CaseIterable {
    case connectivity
    case device
    case data
    case discovery
    case system
    case initialization
    case unknown
}

// MARK: - Test Error (DEBUG only)

#if DEBUG
    /// Unified test error for mocking failures across all test suites
    /// This replaces the individual MockError enums in each test file
    public enum TestError: Error, Equatable, CaseIterable {
        // MARK: - Generic Test Errors

        case generic
        case timeout
        case forbidden

        // MARK: - Device-Specific Test Errors

        case deviceNotFound
        case deviceAlreadyExists
        case deviceConnectionFailed
        case deviceCommandFailure
        case invalidDevice

        // MARK: - MQTT-Specific Test Errors

        case mqttError
        case mqttConnectionFailed
        case mqttPublishFailed
        case mqttSubscriptionFailed

        // MARK: - Data-Specific Test Errors

        case persistenceError
        case serializationError
        case deserializationError
        case cacheError
        case validationError

        // MARK: - Discovery-Specific Test Errors

        case discoveryFailure
        case discoveryTimeout
        case noDevicesFound

        // MARK: - Repository-Specific Test Errors

        case repositoryError
        case addDeviceFailure
        case removeDeviceFailure
        case getDevicesFailure
        case subscriptionFailure
        case commandSendFailure
        case invalidTopic
        case stateRetrievalError

        // MARK: - Use Case-Specific Test Errors

        case useCaseExecutionFailed
        case invalidParameters
        case preconditionFailed
        case postconditionFailed

        // MARK: - App Init Errors

        case initializationError
    }

    extension TestError: LocalizedError {
        public var errorDescription: String? {
            switch self {
            case .generic:
                "A generic test error occurred"
            case .timeout:
                "Test operation timed out"
            case .forbidden:
                "Test forbidden access"
            case .deviceNotFound:
                "Test device not found"
            case .deviceAlreadyExists:
                "Test device already exists"
            case .deviceConnectionFailed:
                "Test device connection failed"
            case .deviceCommandFailure:
                "Test device command failed"
            case .invalidDevice:
                "Test invalid device"
            case .mqttError:
                "Test MQTT error"
            case .mqttConnectionFailed:
                "Test MQTT connection failed"
            case .mqttPublishFailed:
                "Test MQTT publish failed"
            case .mqttSubscriptionFailed:
                "Test MQTT subscription failed"
            case .persistenceError:
                "Test persistence error"
            case .serializationError:
                "Test serialization error"
            case .deserializationError:
                "Test deserialization error"
            case .cacheError:
                "Test cache error"
            case .validationError:
                "Test validation error"
            case .discoveryFailure:
                "Test discovery failure"
            case .discoveryTimeout:
                "Test discovery timeout"
            case .noDevicesFound:
                "Test no devices found"
            case .repositoryError:
                "Test repository error"
            case .addDeviceFailure:
                "Test add device failure"
            case .removeDeviceFailure:
                "Test remove device failure"
            case .getDevicesFailure:
                "Test get devices failure"
            case .subscriptionFailure:
                "Test subscription failure"
            case .commandSendFailure:
                "Test command send failure"
            case .invalidTopic:
                "Test invalid topic"
            case .stateRetrievalError:
                "Test state retrieval error"
            case .useCaseExecutionFailed:
                "Test use case execution failed"
            case .invalidParameters:
                "Test invalid parameters"
            case .preconditionFailed:
                "Test precondition failed"
            case .postconditionFailed:
                "Test postcondition failed"
            case .initializationError:
                "Test app initialization failed"
            }
        }
    }

    // MARK: - Convenience Extensions for Tests

    public extension TestError {
        /// Creates a TestError that matches the given AppError category
        static func matching(_ category: ErrorCategory) -> TestError {
            switch category {
            case .device:
                .deviceNotFound
            case .data:
                .persistenceError
            case .discovery:
                .discoveryFailure
            case .system:
                .timeout
            case .unknown:
                .generic
            case .connectivity:
                .mqttError
            case .initialization:
                .initializationError
            }
        }

        /// Converts this TestError to the corresponding AppError
        func asAppError() -> AppError {
            switch self {
            case .deviceNotFound:
                .deviceNotFound(deviceId: "test_device")
            case .deviceAlreadyExists:
                .deviceAlreadyExists(deviceId: "test_device")
            case .deviceConnectionFailed:
                .deviceConnectionFailed(deviceId: "test_device")
            case .mqttConnectionFailed:
                .mqttConnectionFailed("Test MQTT connection failed")
            case .discoveryFailure:
                .discoveryFailed(reason: "Test discovery failed")
            case .persistenceError:
                .persistenceError(operation: "test_operation")
            case .timeout:
                .timeout(operation: "test_operation")
            default:
                .unknown(underlying: self)
            }
        }
    }
#endif
