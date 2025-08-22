public protocol DeviceConnectionRepositoryProtocol {
    func subscribe() async throws
    func publish() async throws
    func disconnect() async throws
}
