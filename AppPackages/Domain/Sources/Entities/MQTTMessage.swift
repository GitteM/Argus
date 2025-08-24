public struct MQTTMessage: Sendable {
    public let topic: String
    public let payload: String

    public init(topic: String, payload: String) {
        self.topic = topic
        self.payload = payload
    }
}
