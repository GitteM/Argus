import Entities

public protocol DeviceRepositoryProtocol {
    func saveDevice(_ device: Device) async throws
    func getAllDevices() async throws -> [Device]
    func getDevice(id: String) async throws -> Device?
    func updateDevice(_ device: Device) async throws
    func deleteDevice(id: String) async throws
}
