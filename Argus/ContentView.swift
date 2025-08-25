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
