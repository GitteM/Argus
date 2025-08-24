import UseCases

enum DashboardViewState {
    case idle
    case loading
    case data(DashboardData?)
    case error(String)
}
