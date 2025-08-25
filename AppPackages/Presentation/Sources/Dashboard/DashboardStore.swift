import Foundation
import OSLog
import RepositoryProtocols
import Services
import UseCases

@MainActor
public final class DashboardStore: ObservableObject {
    @Published var viewState: DashboardViewState

    private let getDashboardDataUseCase: GetDashboardDataUseCase
    private let logger: LoggerProtocol
    private var task: Task<Void, Never>?

    public init(
        getDashboardDataUseCase: GetDashboardDataUseCase,
        logger: LoggerProtocol
    ) {
        self.getDashboardDataUseCase = getDashboardDataUseCase
        self.logger = logger
        viewState = .loading
    }

    public func loadDashboardData() {
        logger.log("Loading dashboard data", level: .info)
        task?.cancel()
        viewState = .loading

        task = Task { @MainActor in
            do {
                let dashboardData = try await getDashboardDataUseCase.execute()
                guard !Task.isCancelled else {
                    return
                }

                guard !(dashboardData.discoveredDevices.isEmpty
                    && dashboardData.managedDevices.isEmpty)
                else {
                    viewState = .empty
                    return
                }

                viewState = .data(dashboardData)
                logger.log("Dashboard data loaded", level: .info)

            } catch {
                guard let task else { return }
                if !task.isCancelled {
                    viewState = .error(error.localizedDescription)
                }
            }
        }
    }
}
