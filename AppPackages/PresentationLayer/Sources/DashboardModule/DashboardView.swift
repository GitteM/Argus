import CommonModule
import SwiftUI

public struct DashboardView: View {
    @EnvironmentObject private var dashboardState: DashboardState
    @EnvironmentObject private var appState: AppState

    public var body: some View {
        Text("Dashboard")
    }
}
