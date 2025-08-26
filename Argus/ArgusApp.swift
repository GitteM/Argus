import SwiftUI

@main
struct ArgusApp: App {
    private let appContainer = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView(
                deviceStore: appContainer.deviceStore
            )
            .environmentObject(appContainer.connectionManager)
        }
    }
}
