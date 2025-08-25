import SwiftUI

@main
struct ArgusApp: App {
    private let appContainer = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(
                dashboardContainer: appContainer.dashboardContainer,
                dashboardStore: appContainer.dashboardStore,
                settingsContainer: appContainer.settingsContainer
            )
            .environmentObject(appContainer.connectionManager)
        }
    }
}
