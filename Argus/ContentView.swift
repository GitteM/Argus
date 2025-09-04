import DataSource
import Entities
import Infrastructure
import Navigation
import OSLog
import Presentation
import ServiceProtocols
import SharedUI
import Stores
import SwiftUI

struct ContentView: View {
    @Environment(AppContainer.self) private var appContainer

    var body: some View {
        switch appContainer.appState {
        case .initializing, .loading:
            AppLoadingView()

        case .ready:
            MainNavigationView()
                .environment(appContainer.connectionManager)
                .environment(appContainer.router)
                .environment(appContainer.deviceStore)

        case .disconnected:
            DisconnectedView {
                Task {
                    do {
                        try await appContainer.connectionManager.connect()
                    } catch {
                        #if DEBUG
                            // Connection failure will be handled by the status
                            // observer
                            print(
                                "ContentView: Reconnect attempt failed \(error)"
                            )
                        #endif
                    }
                }
            }

        case let .error(appError):
            AppErrorView(
                error: appError,
                retryAction: { appContainer.retry() }
            )
        }
    }
}

#if DEBUG
    #Preview("Loading State") { @MainActor in
        ContentView()
            .environment(AppContainer.loadingPreview)
    }

    #Preview("Ready State") { @MainActor in
        ContentView()
            .environment(AppContainer.preview)
    }

    #Preview("Disconnected State") { @MainActor in
        ContentView()
            .environment(AppContainer.disconnectedPreview)
    }

    #Preview("Error with Recovery Suggestion") { @MainActor in
        ContentView()
            .environment(AppContainer.errorWithRecoveryPreview)
    }

#endif
