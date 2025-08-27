import Combine
import SharedUI
import SwiftUI

@Observable
public final class Router {
    public var routes: [Route]

    public init(routes: [Route] = []) {
        self.routes = routes
    }

    public func navigateBack() {
        guard !routes.isEmpty else { return }
        routes.removeLast()
    }

    public func navigateTo(_ route: Route) {
        routes.append(route)
    }

    public func popToRoot() {
        routes.removeAll()
    }

    public func popTo(_ route: Route) {
        guard let index = routes.firstIndex(of: route) else { return }
        routes.removeSubrange((index + 1)...)
    }
}
