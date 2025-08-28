import Entities
import Navigation
import Observation
import SharedUI
import Stores
import SwiftUI

public struct DashboardContentView: View {
    @Environment(Router.self) private var router
    @Environment(DeviceStore.self) private var deviceStore

    public init() {}

    public var body: some View {
        List {
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
