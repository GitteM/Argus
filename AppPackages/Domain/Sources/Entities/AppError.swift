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

    case fileSystemError(
        operation: String,
        path: String? = nil,
        underlyingError: Error? = nil
    )
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
        case let .fileSystemError(operation, path, error):
            let baseMessage = "File system error during '\(operation)'"
            guard let path else {
                if let errorDescription = error?.localizedDescription {
                    return "\(baseMessage): \(errorDescription)"
                }
                return baseMessage
            }
            let errorDescription = error?.localizedDescription ?? "unknown error"
            return "\(baseMessage) at path '\(path)': \(errorDescription)"
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

// MARK: - Test Helpers

#if DEBUG
    public extension AppError {
        /// Factory methods for creating test-specific AppError instances
        enum TestFactory {
            // MARK: - Generic Test Errors

            public static var generic: AppError { .unknown() }
            public static var timeout: AppError {
                .timeout(operation: "test_operation")
            }

            // MARK: - Device Test Errors

            public static var deviceNotFound: AppError {
                .deviceNotFound(deviceId: "test_device")
            }

            public static var deviceAlreadyExists: AppError {
                .deviceAlreadyExists(deviceId: "test_device")
            }

            public static var deviceConnectionFailed: AppError {
                .deviceConnectionFailed(deviceId: "test_device")
            }

            public static var deviceCommandFailure: AppError {
                .deviceCommandFailed(
                    deviceId: "test_device",
                    command: "test_command"
                )
            }

            // MARK: - MQTT Test Errors

            public static var mqttError: AppError {
                .mqttConnectionFailed("Test MQTT error")
            }

            public static var mqttConnectionFailed: AppError {
                .mqttConnectionFailed("Test MQTT connection failed")
            }

            public static var mqttPublishFailed: AppError {
                .mqttPublishFailed(topic: "test/topic")
            }

            public static var mqttSubscriptionFailed: AppError {
                .mqttSubscriptionFailed(topic: "test/topic")
            }

            // MARK: - Data Test Errors

            public static var persistenceError: AppError {
                .persistenceError(operation: "test_operation")
            }

            public static var serializationError: AppError {
                .serializationError(type: "TestType")
            }

            public static var deserializationError: AppError {
                .deserializationError(type: "TestType")
            }

            public static var cacheError: AppError { .cacheError(
                key: "test_key",
                operation: "test_operation"
            ) }
            public static var validationError: AppError { .validationError(
                field: "test_field",
                reason: "test_reason"
            ) }

            // MARK: - Discovery Test Errors

            public static var discoveryFailure: AppError {
                .discoveryFailed(reason: "Test discovery failed")
            }

            public static var discoveryTimeout: AppError { .discoveryTimeout }
            public static var noDevicesFound: AppError { .noDevicesDiscovered }

            // MARK: - System Test Errors

            public static var repositoryError: AppError {
                .persistenceError(operation: "repository_operation")
            }

            public static var addDeviceFailure: AppError {
                .deviceAlreadyExists(deviceId: "test_device")
            }

            public static var removeDeviceFailure: AppError {
                .deviceNotFound(deviceId: "test_device")
            }

            public static var subscriptionFailure: AppError {
                .mqttSubscriptionFailed(topic: "test/topic")
            }

            public static var commandSendFailure: AppError {
                .deviceCommandFailed(
                    deviceId: "test_device",
                    command: "test_command"
                )
            }

            public static var invalidTopic: AppError { .validationError(
                field: "topic",
                reason: "invalid format"
            ) }

            // MARK: - App Init Test Errors

            public static var initializationError: AppError {
                .initializationError(
                    component: "test_component",
                    reason: "test_reason"
                )
            }
        }
    }
#endif
