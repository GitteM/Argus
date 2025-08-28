import DataSource
import Entities
import Infrastructure
import Navigation
import Presentation
import SharedUI
import Stores
import SwiftUI

struct ContentView: View {
    @Environment(MQTTConnectionManager.self) private var connectionManager
    @Environment(Router.self) private var router
    @Environment(DeviceStore.self) private var deviceStore

    private var connectionStatus: MQTTConnectionStatus {
        connectionManager.connectionStatus
    }

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.routes) {
            DashboardView()
                .navigationDestination(for: Route.self) { route in
                    route.destination(router: router)
                }
                .mqttConnectionHandler()
                .navigationTitle(Strings.devices)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ConnectionStatusIndicator(status: connectionStatus)
                }
        }
    }
}

#Preview("Light Mode") { @MainActor in
    let appContainer = AppContainer()
    ContentView()
        .environment(appContainer.connectionManager)
        .environment(appContainer.deviceStore)
        .environment(appContainer.router)
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") { @MainActor in
    let appContainer = AppContainer()
    ContentView()
        .environment(appContainer.connectionManager)
        .environment(appContainer.deviceStore)
        .environment(appContainer.router)
        .preferredColorScheme(.dark)
}
