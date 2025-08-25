import Infrastructure
import Navigation
import SharedUI
import SwiftUI

public struct DashboardView: View {
    @EnvironmentObject private var dashboardStore: DashboardStore
    @EnvironmentObject private var appState: AppState

    public init() {}

    public var body: some View {
        Text("🚧 Dashboard 🚧")
    }
}

// MARK: - Factory Extension

public extension DashboardView {
    @MainActor
    static func create(from container: DashboardContainer) -> some View {
        DashboardView()
            .environmentObject(DashboardStore(getDashboardDataUseCase: container.getDashboardDataUseCase))
            .environmentObject(AppState())
    }
}
