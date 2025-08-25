import Dashboard
import DataSource
import Entities
import Infrastructure
import RepositoryProtocols
import Settings
import SharedUI
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var connectionManager: MQTTConnectionManager

    let dashboardContainer: DashboardContainer
    let settingsContainer: SettingsContainer

    private var connectionStatus: MQTTConnectionStatus {
        connectionManager.connectionStatus
    }

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView.create(from: dashboardContainer)
                    .navigationTitle("Devices")
                    .mqttConnectionHandler()
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ConnectionStatusIndicator(status: connectionStatus)
                    }
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }

            NavigationStack {
                SettingsView.create(from: settingsContainer)
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
        }
    }
}

#Preview("Light Mode") {
    let appContainer = AppContainer()
    ContentView(
        dashboardContainer: appContainer.dashboardContainer,
        settingsContainer: appContainer.settingsContainer
    )
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    let appContainer = AppContainer()
    ContentView(
        dashboardContainer: appContainer.dashboardContainer,
        settingsContainer: appContainer.settingsContainer
    )
    .preferredColorScheme(.dark)
}
