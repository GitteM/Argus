import Entities
import Navigation
import Observation
import SharedUI
import SwiftUI

public struct DashboardContentView: View {
    @Environment(Router.self) private var router

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

#Preview("Light Mode") {
    DashboardContentView(
        subscribedDevices: [.mockConnected],
        availableDevices: DiscoveredDevice.mockDefaults
    )
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    DashboardContentView(
        subscribedDevices: Device.mockDefaults,
        availableDevices: DiscoveredDevice.mockDefaults
    )
    .preferredColorScheme(.dark)
}

#Preview("Empty") {
    DashboardContentView(
        subscribedDevices: [],
        availableDevices: []
    )
    .preferredColorScheme(.light)
}
