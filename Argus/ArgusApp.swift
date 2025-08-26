import SwiftUI

@main
struct ArgusApp: App {
    private let appContainer = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(
                dashboardContainer: appContainer.dashboardContainer,
                deviceStore: appContainer.deviceStore,
                settingsContainer: appContainer.settingsContainer
            )
            .environmentObject(appContainer.connectionManager)
        }
    }
}
