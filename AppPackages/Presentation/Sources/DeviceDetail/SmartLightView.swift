import Entities
import SharedUI
import SwiftUI

struct SmartLightView: View {
    let device: Device
    let lightState: LightState?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l2) {
            Text(Strings.lightControls)
                .font(.headline)

            if let lightState {
                VStack(alignment: .leading, spacing: Spacing.s3) {
                    HStack {
                        Text("\(Strings.status):")
                        Text(lightState.state ? Strings.on : Strings.off)
                            .foregroundColor(lightState.state ? .green : .red)
                            .fontWeight(.semibold)
                    }

                    if let brightness = lightState.brightness {
                        HStack {
                            Text("\(Strings.brightness):")
                            Text("\(brightness)%")
                                .bold()
                        }
                    }

                    Text(
                        "\(Strings.lastUpdated): \(lightState.date.abbreviatedDateTime)"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            } else {
                Text(Strings.noLightStateAvailable)
                    .foregroundColor(.secondary)
            }

            DeviceInfoSection(device: device)
        }
        .padding()
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }
}

#if DEBUG

    #Preview("Light On with Brightness") {
        SmartLightView(
            device: .mockLight,
            lightState: .mockOnWithBrightness
        )
        .padding()
    }

    #Preview("Light Off") {
        SmartLightView(
            device: .mockLight,
            lightState: .mockOff
        )
        .padding()
    }

    #Preview("No Light State") {
        SmartLightView(
            device: .mockLight,
            lightState: nil
        )
        .padding()
    }

#endif
