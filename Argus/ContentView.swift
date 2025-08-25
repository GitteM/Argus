import Dashboard
import DataSource
import Entities
import Infrastructure
import Presentation
import Settings
import SharedUI
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var connectionManager: MQTTConnectionManager

    let dashboardContainer: DashboardContainer
    let dashboardStore: DashboardStore
    let settingsContainer: SettingsContainer

    private var connectionStatus: MQTTConnectionStatus {
        connectionManager.connectionStatus
    }

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
                    .environmentObject(dashboardStore)
                    .mqttConnectionHandler()
                    .navigationTitle(Strings.devices)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ConnectionStatusIndicator(status: connectionStatus)
                    }
            }
            .tabItem {
                Image(systemName: Icons.home)
                Text(Strings.home)
            }

            NavigationStack {
                SettingsView.create(from: settingsContainer)
                    .navigationTitle(Strings.settings)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ConnectionStatusIndicator(status: connectionStatus)
                    }
            }
            .tabItem {
                Image(systemName: Icons.settings)
                Text(Strings.settings)
            }
        }
    }
}

#Preview("Light Mode") { @MainActor in
    let appContainer = AppContainer()
    ContentView(
        dashboardContainer: appContainer.dashboardContainer,
        dashboardStore: appContainer.dashboardStore,
        settingsContainer: appContainer.settingsContainer
    )
    .environmentObject(appContainer.connectionManager)
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") { @MainActor in
    let appContainer = AppContainer()
    ContentView(
        dashboardContainer: appContainer.dashboardContainer,
        dashboardStore: appContainer.dashboardStore,
        settingsContainer: appContainer.settingsContainer
    )
    .environmentObject(appContainer.connectionManager)
    .preferredColorScheme(.dark)
}
