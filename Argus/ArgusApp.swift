import Infrastructure
import SwiftUI

@main
struct ArgusApp: App {
    private let appContainer = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(
                dashboardContainer: appContainer.dashboardContainer,
                settingsContainer: appContainer.settingsContainer
            )
            .environmentObject(appContainer.connectionManager)
        }
    }
}
