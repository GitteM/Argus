import Dashboard
import DataSource
import Entities
import Navigation
import SharedUI
import Stores
import SwiftUI

struct MainNavigationView: View {
    @Environment(MQTTConnectionManager.self) private var connectionManager
    @Environment(Router.self) private var router

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
                .navigationTitle(Strings.devices)
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .toolbar {
                    ConnectionStatusIndicator(
                        status: connectionStatus
                    )
                }
        }
    }
}
