import Entities
import Navigation
import Observation
import SharedUI
import Stores
import SwiftUI

public struct DashboardContentView: View {
    @Environment(DeviceStore.self) private var deviceStore

    public init() {}

    public var body: some View {
        List {
            SubscribedDevicesSection()
            DiscoveredDevicesSection()
        }
        .refreshable {
            deviceStore.loadDashboardData()
        }
    }
}

private extension DashboardContentView {
    struct SubscribedDevicesSection: View {
        @Environment(DeviceStore.self) private var deviceStore
        @Environment(Router.self) private var router

        var body: some View {
            Section {
                if deviceStore.devices.isEmpty {
                    WarningRow(message: Strings.subscribeToDeviceWarning)
                } else {
                    ForEach(deviceStore.devices, id: \.id) { device in
                        DeviceSubscribedRow(device: device)
                            .onRowTap {
                                deviceStore.selectDevice(device)
                                router.navigateTo(.deviceDetail)
                            }
                    }
                }
            } header: {
                Text(Strings.subscribed)
            }
        }
    }

    struct DiscoveredDevicesSection: View {
        @Environment(DeviceStore.self) private var deviceStore

        var body: some View {
            if !deviceStore.discoveredDevices.isEmpty {
                Section {
                    ForEach(deviceStore.discoveredDevices, id: \.id) { device in
                        DeviceAvailableRow(device: device)
                    }
                } header: {
                    Text(Strings.availableNotSubscribed)
                }
            }
        }
    }
}

#if DEBUG

    #Preview("Light Mode") { @MainActor in
        let router = Router()
        let store = DeviceStore.preview

        DashboardContentView()
            .environment(router)
            .environment(store)
            .preferredColorScheme(.light)
            .task {
                store.loadDashboardData()
            }
    }

    #Preview("Dark Mode") { @MainActor in
        let router = Router()
        let store = DeviceStore.preview

        DashboardContentView()
            .environment(router)
            .environment(store)
            .preferredColorScheme(.dark)
            .task {
                store.loadDashboardData()
            }
    }

    #Preview("Empty") { @MainActor in
        let router = Router()
        let store = DeviceStore.emptyPreview
        DashboardContentView()
            .environment(router)
            .environment(store)
            .preferredColorScheme(.light)
            .task {
                store.loadDashboardData()
            }
    }

#endif
