import DeviceDetail
import SharedUI
import SwiftUI

public extension Route {
    @ViewBuilder @MainActor
    func destination(router: Router) -> some View {
        switch self {
        case .deviceDetail:
            DeviceDetailView { route in
                switch route {
                case .back:
                    router.navigateBack()
                case .deviceDetail:
                    router.navigateTo(.deviceDetail)
                }
            }

        case .back:
            EmptyView()
        }
    }
}
