public protocol MQTTRepositoryProtocol {
    func subscribe() async throws
    func publish() async throws
    func disconnect() async throws
}
