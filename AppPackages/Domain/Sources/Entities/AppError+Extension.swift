// MARK: - Equatable Conformance

extension AppError: Equatable {
    public static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.mqttConnectionFailed, .mqttConnectionFailed),
             (.mqttNotConnected, .mqttNotConnected),
             (.mqttPublishFailed, .mqttPublishFailed),
             (.mqttSubscriptionFailed, .mqttSubscriptionFailed):
            compareConnectionErrors(lhs, rhs)

        case (.deviceNotFound, .deviceNotFound),
             (.deviceAlreadyExists, .deviceAlreadyExists),
             (.deviceConnectionFailed, .deviceConnectionFailed),
             (.deviceCommandFailed, .deviceCommandFailed),
             (.invalidDeviceConfiguration, .invalidDeviceConfiguration):
            compareDeviceErrors(lhs, rhs)

        case (.persistenceError, .persistenceError),
             (.cacheError, .cacheError),
             (.serializationError, .serializationError),
             (.deserializationError, .deserializationError),
             (.validationError, .validationError):
            compareDataErrors(lhs, rhs)

        case (.discoveryFailed, .discoveryFailed),
             (.discoveryTimeout, .discoveryTimeout),
             (.noDevicesDiscovered, .noDevicesDiscovered):
            compareDiscoveryErrors(lhs, rhs)

        case (.fileSystemError, .fileSystemError),
             (.configurationError, .configurationError),
             (.serviceUnavailable, .serviceUnavailable),
             (.timeout, .timeout):
            compareSystemErrors(lhs, rhs)

        case (.unknown, .unknown):
            compareUnknownErrors(lhs, rhs)

        default:
            false
        }
    }
}

private extension AppError {
    static func compareConnectionErrors(
        _ lhs: AppError,
        _ rhs: AppError
    ) -> Bool {
        switch (lhs, rhs) {
        case let (
            .mqttConnectionFailed(lhsDetails),
            .mqttConnectionFailed(rhsDetails)
        ):
            lhsDetails == rhsDetails
        case (.mqttNotConnected, .mqttNotConnected):
            true
        case let (.mqttPublishFailed(lhsTopic), .mqttPublishFailed(rhsTopic)),
             let (
                 .mqttSubscriptionFailed(lhsTopic),
                 .mqttSubscriptionFailed(rhsTopic)
             ):
            lhsTopic == rhsTopic
        default:
            false
        }
    }

    static func compareDeviceErrors(_ lhs: AppError, _ rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case let (.deviceNotFound(lhsId), .deviceNotFound(rhsId)),
             let (.deviceAlreadyExists(lhsId), .deviceAlreadyExists(rhsId)),
             let (
                 .deviceConnectionFailed(lhsId),
                 .deviceConnectionFailed(rhsId)
             ):
            lhsId == rhsId
        case let (
            .deviceCommandFailed(lhsId, lhsCmd),
            .deviceCommandFailed(rhsId, rhsCmd)
        ):
            lhsId == rhsId && lhsCmd == rhsCmd
        case let (
            .invalidDeviceConfiguration(lhsReason),
            .invalidDeviceConfiguration(rhsReason)
        ):
            lhsReason == rhsReason
        default:
            false
        }
    }

    static func compareDataErrors(_ lhs: AppError, _ rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case let (
            .persistenceError(lhsOp, lhsDetails),
            .persistenceError(rhsOp, rhsDetails)
        ):
            lhsOp == rhsOp && lhsDetails == rhsDetails
        case let (.cacheError(lhsKey, lhsOp), .cacheError(rhsKey, rhsOp)):
            lhsKey == rhsKey && lhsOp == rhsOp
        case let (
            .serializationError(lhsType, lhsDetails),
            .serializationError(rhsType, rhsDetails)
        ),
        let (
            .deserializationError(lhsType, lhsDetails),
            .deserializationError(rhsType, rhsDetails)
        ):
            lhsType == rhsType && lhsDetails == rhsDetails
        case let (
            .validationError(lhsField, lhsReason),
            .validationError(rhsField, rhsReason)
        ):
            lhsField == rhsField && lhsReason == rhsReason
        default:
            false
        }
    }

    static func compareDiscoveryErrors(
        _ lhs: AppError,
        _ rhs: AppError
    ) -> Bool {
        switch (lhs, rhs) {
        case let (.discoveryFailed(lhsReason), .discoveryFailed(rhsReason)):
            lhsReason == rhsReason
        case (.discoveryTimeout, .discoveryTimeout),
             (.noDevicesDiscovered, .noDevicesDiscovered):
            true
        default:
            false
        }
    }

    static func compareSystemErrors(_ lhs: AppError, _ rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case let (
            .fileSystemError(lhsOp, lhsPath, lhsError),
            .fileSystemError(rhsOp, rhsPath, rhsError)
        ):
            lhsOp == rhsOp && lhsPath == rhsPath && compareOptionalErrors(
                lhsError,
                rhsError
            )
        case let (
            .configurationError(lhsComponent, lhsReason),
            .configurationError(rhsComponent, rhsReason)
        ):
            lhsComponent == rhsComponent && lhsReason == rhsReason
        case let (
            .serviceUnavailable(lhsService),
            .serviceUnavailable(rhsService)
        ):
            lhsService == rhsService
        case let (.timeout(lhsOp, lhsDuration), .timeout(rhsOp, rhsDuration)):
            lhsOp == rhsOp && lhsDuration == rhsDuration
        default:
            false
        }
    }

    static func compareUnknownErrors(_ lhs: AppError, _ rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case let (.unknown(lhsUnderlying), .unknown(rhsUnderlying)):
            compareOptionalErrors(lhsUnderlying, rhsUnderlying)
        default:
            false
        }
    }

    static func compareOptionalErrors(_ lhs: Error?, _ rhs: Error?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            true
        case let (lhsError?, rhsError?):
            String(describing: lhsError) == String(describing: rhsError)
        default:
            false
        }
    }
}
