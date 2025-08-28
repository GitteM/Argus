import Entities
import Infrastructure
import SharedUI
import Stores
import SwiftUI
import UseCases

public struct DashboardView: View {
    @Environment(DeviceStore.self) private var deviceStore

    public init() {}

    public var body: some View {
        switch deviceStore.viewState {
        case .loading:
            LoadingView()
                .onAppear {
                    deviceStore.loadDashboardData()
                }

        case .loaded:
            DashboardContentView()

        case .empty:
            EmptyStateView(
                message: "No data available",
                icon: "questionmark.circle"
            )

        case let .error(error):
            ErrorView(
                message: error,
                retryAction: { deviceStore.loadDashboardData() }
            )
        }
    }
}
