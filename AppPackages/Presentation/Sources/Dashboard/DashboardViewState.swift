import UseCases

enum DashboardViewState {
    case loading
    case data(DashboardData)
    case error(String)
    case empty
}
