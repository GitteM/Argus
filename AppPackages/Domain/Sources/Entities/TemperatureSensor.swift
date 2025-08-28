import Foundation

public struct TemperatureSensor: Sendable, Codable {
    public let temperature: Double
    public let date: Date
    public let battery: Int

    public init(
        temperature: Double,
        date: Date,
        battery: Int
    ) {
        self.temperature = temperature
        self.date = date
        self.battery = battery
    }

    enum CodingKeys: String, CodingKey {
        case temperature, battery
        case date = "timestamp"
    }
}

public extension TemperatureSensor {
    static let mockTemperature: TemperatureSensor = .init(
        temperature: 22.5,
        date: Date(),
        battery: 100
    )

    static let mockLowBattery: TemperatureSensor = .init(
        temperature: 22.5,
        date: Date(),
        battery: 15
    )
}
