import Entities

public protocol RESTDataSourceProtocol: Sendable {
    func getDeviceState(deviceId: String) async throws -> DeviceState
}

public actor RESTDataSource: RESTDataSourceProtocol {
    public init() {}

    public func getDeviceState(deviceId _: String) async throws -> DeviceState {
        fatalError("Not implemented")
    }
}
