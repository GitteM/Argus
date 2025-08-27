import DataSource
import Entities
import SharedUI
import Stores
import SwiftUI

public struct DeviceDetailView: View {
    @Environment(MQTTConnectionManager.self) private var connectionManager
    @Environment(DeviceStore.self) private var deviceStore

    private let onNavigate: (Route) -> Void

    private var connectionStatus: MQTTConnectionStatus {
        connectionManager.connectionStatus
    }

    public init(
        onNavigate: @escaping (Route) -> Void = { _ in }
    ) {
        self.onNavigate = onNavigate
    }

    public var body: some View {
        Text("DeviceDetail")
            .navigationTitle("Selected Device name")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                BackToolbarItem {
                    onNavigate(.back)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    ConnectionStatusIndicator(status: connectionStatus)
                }
            }
    }
}
