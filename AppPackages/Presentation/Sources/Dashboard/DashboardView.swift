import Entities
import Infrastructure
import SharedUI
import SwiftUI
import UseCases

public struct DashboardView: View {
    @EnvironmentObject private var dashboardStore: DashboardStore

    public init() {}

    public var body: some View {
        switch dashboardStore.viewState {
        case .loading:
            LoadingView()
                .onAppear {
                    dashboardStore.loadDashboardData()
                }

        case let .data(data):
            DashboardContentView(
                subscribedDevices: data.managedDevices,
                availableDevices: data.discoveredDevices
            )

        case .empty:
            EmptyStateView(
                message: "No data available",
                icon: "questionmark.circle"
            )

        case let .error(error):
            ErrorView(
                message: error,
                retryAction: { dashboardStore.loadDashboardData() }
            )
        }
    }
}
