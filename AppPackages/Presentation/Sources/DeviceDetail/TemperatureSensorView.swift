import Entities
import SwiftUI

struct TemperatureSensorView: View {
    let device: Device
    let temperatureSensor: TemperatureSensor?

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("Temperature Sensor")
                .font(.headline)

            if let temperatureSensor {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Temperature:")
                        Text(
                            "\(temperatureSensor.temperature, specifier: "%.1f")"
                        )
                        .fontWeight(.semibold)
                        if let unit = device.unitOfMeasurement {
                            Text(unit)
                        }
                    }

                    HStack {
                        Text("Battery:")
                        Text("\(temperatureSensor.battery)%")
                            .foregroundColor(batteryColor(for: temperatureSensor
                                    .battery
                            ))
                            .fontWeight(.semibold)
                    }

                    Text("Last Reading: \(temperatureSensor.date.formatted())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("No temperature data available")
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

    private func batteryColor(for batteryLevel: Int) -> Color {
        switch batteryLevel {
        case 0 ... 20:
            .red
        case 21 ... 50:
            .orange
        default:
            .green
        }
    }
}

#Preview("Temperature Sensor with Data") {
    TemperatureSensorView(
        device: .mockTemperatureSensor,
        temperatureSensor: .mockTemperature
    )
    .padding()
}

#Preview("Low Battery") {
    TemperatureSensorView(
        device: .mockTemperatureSensor,
        temperatureSensor: .mockLowBattery
    )
    .padding()
}

#Preview("No Temperature Data") {
    TemperatureSensorView(
        device: .mockTemperatureSensor,
        temperatureSensor: nil
    )
    .padding()
}
