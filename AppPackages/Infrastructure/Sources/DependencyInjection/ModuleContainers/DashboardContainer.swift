import UseCases

public final class DashboardContainer {
    public let getDashboardDataUseCase: GetDashboardDataUseCase

    public init(getDashboardDataUseCase: GetDashboardDataUseCase) {
        self.getDashboardDataUseCase = getDashboardDataUseCase
    }
}
