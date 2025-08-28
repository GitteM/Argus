import DataSource
import Entities
import ServiceProtocols
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
        #if os(iOS)
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
        #endif
    }

    @ViewBuilder
    private var contentView: some View {
        if let device = deviceStore.selectedDevice {
            VStack(spacing: 0) {
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
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        DeviceInfoSection(device: device)
                        ErrorView(
                            message: Strings.unknownDeviceType
                        )
                    }
                    .padding()
                }

                VStack {
                    Divider()

                    DestructiveButton(
                        title: Strings.unsubscribeFromDevice
                    ) {
                        deviceStore.unsubscribeFromDevice(withId: device.id)
                        deviceStore.clearSelection()
                        onNavigate(.back)
                    }
                }
            }
        } else {
            ErrorView(
                message: Strings.selectDevicetoViewDetails
            )
        }
    }

    private var navigationTitle: String {
        deviceStore.selectedDevice?.name ?? Strings.deviceDetail
    }
}

#if DEBUG

    #Preview("Smart Light") { @MainActor in
        let store = DeviceStore.preview
        let connectionManager = MQTTConnectionManager.preview

        Task { @MainActor in
            store.loadDashboardData()
            store.selectDevice(.mockLight)
        }

        return DeviceDetailView { _ in }
            .environment(store)
            .environment(connectionManager)
    }

    #Preview("Temperature Sensor") { @MainActor in
        let store = DeviceStore.preview
        let connectionManager = MQTTConnectionManager.preview

        Task { @MainActor in
            store.loadDashboardData()
            store
                .selectDevice(.mockTemperatureSensor)
        }

        return DeviceDetailView { _ in }
            .environment(store)
            .environment(connectionManager)
    }

    #Preview("No Selection") { @MainActor in
        let store = DeviceStore.emptyPreview
        let connectionManager = MQTTConnectionManager.preview

        DeviceDetailView { _ in }
            .environment(store)
            .environment(connectionManager)
            .task {
                store.loadDashboardData()
            }
    }

#endif
