import SwiftUI

struct AlertsView: View {
    @Environment(AlertsState.self) var alertState

    var body: some View {
        Text("AlertsView")
    }
}
