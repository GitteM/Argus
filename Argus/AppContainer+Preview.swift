import Configuration
import DataSource
import DependencyInjection
import Entities
import Foundation
import Infrastructure
import Navigation
import OSLog
import Persistence
import Repositories
import RepositoryProtocols
import ServiceProtocols
import Services
import Stores
import UseCases

#if DEBUG

    // MARK: - AppContainer Preview Extension

    @MainActor
    extension AppContainer {
        /// Preview AppContainer in ready state with mock data
        static var preview: AppContainer {
            AppContainer(previewState: .ready)
        }

        /// Preview AppContainer in loading state
        static var loadingPreview: AppContainer {
            AppContainer(previewState: .loading)
        }

        /// Preview AppContainer in disconnected state
        static var disconnectedPreview: AppContainer {
            AppContainer(previewState: .disconnected)
        }

        /// Preview AppContainer in error state with basic error
        static var errorPreview: AppContainer {
            let error = AppError.fileSystemError(
                operation: "create",
                path: "/invalid/path"
            )
            return AppContainer(previewState: .error(error))
        }

        /// Preview AppContainer in error state with recovery suggestion
        static var errorWithRecoveryPreview: AppContainer {
            let error = AppError.initializationError(
                component: "AppContainer",
                reason: "Failed to create cache directory"
            )
            return AppContainer(previewState: .error(error))
        }
    }

    // MARK: - Mock MQTT Connection Manager

    private final class MockMQTTConnectionManager: MQTTConnectionManager,
        @unchecked Sendable {
        init(status _: MQTTConnectionStatus = .connected) {
            super.init(
                clientId: "preview-client",
                broker: "localhost",
                port: 1883,
                logger: MockLogger()
            )
        }

        override func connect() async throws {
            // Mock implementation - do nothing
        }

        override func disconnect() {
            // Mock implementation - do nothing
        }
    }

    // MARK: - Mock Logger

    private final class MockLogger: LoggerProtocol {
        func log(_: String, level _: OSLogType) {}
    }

#endif
