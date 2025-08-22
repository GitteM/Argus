import Entities
import RepositoryProtocols

public struct DeviceRepository: DeviceRepositoryProtocol {
    public func saveDevice(_: Device) async throws {
        fatalError("Not Implemented")
    }

    public func getAllDevices() async throws -> [Device] {
        fatalError("Not Implemented")
    }

    public func getDevice(id _: String) async throws -> Device? {
        fatalError("Not Implemented")
    }

    public func updateDevice(_: Device) async throws {
        fatalError("Not Implemented")
    }

    public func deleteDevice(id _: String) async throws {
        fatalError("Not Implemented")
    }
}
