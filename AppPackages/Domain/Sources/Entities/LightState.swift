import Foundation

public struct LightState: Sendable, Codable {
    public let state: Bool
    public let brightness: Int?
    public let date: Date

    public init(
        state: Bool,
        brightness: Int?,
        date: Date
    ) {
        self.state = state
        self.brightness = brightness
        self.date = date
    }

    enum CodingKeys: String, CodingKey {
        case state, brightness
        case date = "timestamp"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let stateString = try? container
            .decode(String.self, forKey: .state) {
            state = stateString.lowercased() == "on"
        } else {
            state = try container.decode(Bool.self, forKey: .state)
        }

        brightness = try container.decodeIfPresent(
            Int.self,
            forKey: .brightness
        )
        date = try container.decode(Date.self, forKey: .date)
    }
}

public extension LightState {
    static let mockOnWithBrightness = LightState(
        state: true,
        brightness: 75,
        date: Date()
    )

    static let mockOff = LightState(
        state: false,
        brightness: 0,
        date: Date()
    )
}
