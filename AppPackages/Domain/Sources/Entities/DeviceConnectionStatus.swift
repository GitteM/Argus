public enum DeviceConnectionStatus: String, CaseIterable, Codable, Sendable {
    case disconnected
    case connecting
    case connected
    case reconnecting
    case failed
}
