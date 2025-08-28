import Entities
import Navigation
import Observation
import SharedUI
import Stores
import SwiftUI

public struct DashboardContentView: View {
    @Environment(Router.self) private var router
    @Environment(DeviceStore.self) private var deviceStore

    let subscribedDevices: [Device]
    let availableDevices: [DiscoveredDevice]

    public init(
        subscribedDevices: [Device],
        availableDevices: [DiscoveredDevice]
    ) {
        self.subscribedDevices = subscribedDevices
        self.availableDevices = availableDevices
    }

    public var body: some View {
        List {
            Section {
                if subscribedDevices.isEmpty {
                    WarningRow(message: Strings.subscribeToDeviceWarning)
                } else {
                    ForEach(subscribedDevices, id: \.id) { device in
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

            if !availableDevices.isEmpty {
                Section {
                    ForEach(availableDevices, id: \.id) { device in
                        DeviceAvailableRow(device: device)
                    }
                } header: {
                    Text(Strings.availableNotSubscribed)
                }
            }
        }
    }
}

// FIXME: need to configure environment
//
// #Preview("Light Mode") { @MainActor in
//    let router = Router()
//
//    DashboardContentView(
//        subscribedDevices: [.mockConnected],
//        availableDevices: DiscoveredDevice.mockDefaults
//    )
//    .environment(router)
//    .preferredColorScheme(.light)
// }
//
// #Preview("Dark Mode") {
//    DashboardContentView(
//        subscribedDevices: Device.mockDefaults,
//        availableDevices: DiscoveredDevice.mockDefaults
//    )
//    .environment(Router())
//    .preferredColorScheme(.dark)
// }
//
// #Preview("Empty") {
//    DashboardContentView(
//        subscribedDevices: [],
//        availableDevices: []
//    )
//    .environment(Router())
//    .preferredColorScheme(.light)
// }
