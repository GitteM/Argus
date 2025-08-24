import Foundation
import UseCases

@MainActor
public final class DashboardStore: ObservableObject {
    @Published var viewState: DashboardViewState

    private let getDashboardDataUseCase: GetDashboardDataUseCase
    private var task: Task<Void, Never>?

    public init(
        getDashboardDataUseCase: GetDashboardDataUseCase
    ) {
        viewState = .idle
        self.getDashboardDataUseCase = getDashboardDataUseCase
    }

    public func loadDashboardData() {
        task?.cancel()
        viewState = .loading

        task = Task {
            do {
                let dashboardData = try await getDashboardDataUseCase.execute()
                guard !Task.isCancelled else { return }
                viewState = .data(dashboardData)
            } catch {
                guard let task else { return }
                if !task.isCancelled {
                    viewState = .error(error.localizedDescription)
                }
            }
        }
    }
}
