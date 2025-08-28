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
        contentView
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                BackToolbarItem {
                    deviceStore.clearSelection()
                    onNavigate(.back)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    ConnectionStatusIndicator(status: connectionStatus)
                }
            }
    }

    @ViewBuilder
    private var contentView: some View {
        if let device = deviceStore.selectedDevice {
            switch device.type {
            case .smartLight:
                SmartLightView(
                    device: device,
                    lightState: deviceStore.selectedDeviceState?.lightState
                )

            case .temperatureSensor:
                TemperatureSensorView(
                    device: device,
                    temperatureSensor: deviceStore.selectedDeviceState?
                        .temperatureSensor
                )

            case .unknown:
                VStack(alignment: .leading, spacing: 16) {
                    DeviceInfoSection(device: device)
                    ErrorView(
                        message: "Unknown device type"
                    )
                }
                .padding()
            }
        } else {
            ErrorView(
                message: "Please select a device to view its details."
            )
        }
    }

    private var navigationTitle: String {
        deviceStore.selectedDevice?.name ?? "Device Detail"
    }
}
