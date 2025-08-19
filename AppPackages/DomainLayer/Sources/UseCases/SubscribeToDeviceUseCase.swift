import Entities

public typealias SubscribeToDeviceResult = Result<Device, Error>

public protocol SubscribeToDeviceUseCaseProtocol {
    func execute() async throws -> SubscribeToDeviceResult
}
