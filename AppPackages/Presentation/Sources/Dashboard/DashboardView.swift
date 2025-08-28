import Entities
import Infrastructure
import Navigation
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

#if DEBUG

    #Preview("Loaded State") { @MainActor in
        let store = DeviceStore.preview
        let router = Router()

        DashboardView()
            .environment(store)
            .environment(router)
            .task {
                store.loadDashboardData()
            }
    }

    #Preview("Loading State") { @MainActor in
        let store = DeviceStore.loadingPreview
        let router = Router()
        DashboardView()
            .environment(store)
            .environment(router)
    }

    #Preview("Empty State") { @MainActor in
        let store = DeviceStore.emptyPreview
        let router = Router()

        DashboardView()
            .environment(store)
            .environment(router)
            .task {
                store.loadDashboardData()
            }
    }

    #Preview("Error State") { @MainActor in
        let store = DeviceStore.errorPreview
        let router = Router()

        DashboardView()
            .environment(store)
            .environment(router)
            .task {
                store.loadDashboardData()
            }
    }

#endif
