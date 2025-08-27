import Navigation
import SwiftUI

@main
struct ArgusApp: App {
    private let appContainer = AppContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appContainer.connectionManager)
                .environment(appContainer.router)
                .environment(appContainer.deviceStore)
        }
    }
}
