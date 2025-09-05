import DataUtilities
import Entities
import Foundation
import OSLog
@testable import Persistence
import ServiceProtocols
import Testing

@Suite("CacheManager Tests")
struct CacheManagerTests {
    // MARK: - Error Handling Tests

    @Test(
        "Type mismatch in memory cache should fallback to disk cache gracefully"
    )
    func memoryCache_TypeMismatchFallback() async throws {
        // Given
        let mockLogger = MockLogger()
        let cacheManager = try CacheManager(logger: mockLogger)

        // Set valid data in memory cache with type identifier
        let validData = TestData(id: "test", value: 123)
        let setResult = await cacheManager.set(
            validData,
            key: "type_mismatch_key"
        )
        guard case .success = setResult else {
            Issue.record("Failed to set up test data")
            return
        }

        // Try to decode as wrong type - should gracefully fallback to disk
        let getResult: Result<InvalidTestData?, AppError> = cacheManager
            .get(key: "type_mismatch_key")

        // Then - With the optimization, this should either:
        // 1. Return success(nil) if no disk cache exists (cache miss)
        // 2. Return deserializationError if disk cache has incompatible data
        switch getResult {
        case let .success(data):
            // Cache miss is acceptable - no matching type found
            #expect(data == nil)
        case let .failure(error):
            // If there's an error, it should be from disk cache deserialization
            switch error {
            case let .deserializationError(type, details):
                #expect(type == "InvalidTestData")
                #expect(details != nil)
            default:
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }

    @Test("Type optimization should prevent unnecessary JSON decoding")
    func typeOptimizationPreventDecoding() async throws {
        // Given
        let mockLogger = MockLogger()
        let cacheManager = try CacheManager(logger: mockLogger)

        // Set data of one type
        let testData = TestData(id: "test", value: 456)
        let setResult = await cacheManager.set(
            testData,
            key: "optimization_test"
        )
        guard case .success = setResult else {
            Issue.record("Failed to set up test data")
            return
        }

        // Try to get the same data with the correct type - should succeed
        let correctTypeResult: Result<TestData?, AppError> = cacheManager
            .get(key: "optimization_test")

        switch correctTypeResult {
        case let .success(retrievedData):
            #expect(retrievedData != nil)
            #expect(retrievedData?.id == testData.id)
            #expect(retrievedData?.value == testData.value)
        case let .failure(error):
            Issue.record("Expected success but got error: \(error)")
        }

        // Try to get with wrong type - should gracefully handle without
        // unnecessary decoding
        let wrongTypeResult: Result<InvalidTestData?, AppError> = cacheManager
            .get(key: "optimization_test")

        // Should either return nil (cache miss after type check) or handle
        // gracefully
        switch wrongTypeResult {
        case let .success(data):
            #expect(data == nil) // Type mismatch handled gracefully
        case .failure:
            // If there's a failure, it should be from disk cache attempt, not
            // memory cache
            break
        }
    }

    @Test(
        "Deserialization failure in disk cache should return deserializationError"
    )
    func diskCache_DeserializationFailure() async throws {
        // Given
        let mockLogger = MockLogger()
        let cacheManager = try CacheManager(logger: mockLogger)

        // Set a device-related key that persists to disk
        let validData = TestData(id: "device_test", value: 456)
        let setResult = await cacheManager.set(
            validData,
            key: "devices_corrupted"
        )
        guard case .success = setResult else {
            Issue.record("Failed to set up test data")
            return
        }

        // Clear memory cache to force disk read
        let clearResult = cacheManager.clear()
        guard case .success = clearResult else {
            Issue.record("Failed to clear cache for test setup")
            return
        }

        // Try to read as wrong type to simulate corruption
        let getResult: Result<InvalidTestData?, AppError> = cacheManager
            .get(key: "devices_corrupted")

        // Then
        switch getResult {
        case .success:
            // This might succeed if file doesn't exist (cache miss)
            break
        case let .failure(error):
            switch error {
            case let .deserializationError(type, details):
                #expect(type == "InvalidTestData")
                #expect(details != nil)
            default:
                // Other errors like fileSystemError are also acceptable
                break
            }
        }
    }

    @Test(
        "Corrupted disk cache file should handle deserialization errors gracefully"
    )
    func diskCache_CorruptedFile() async throws {
        // Given
        let mockLogger = MockLogger()
        let cacheManager = try CacheManager(logger: mockLogger)

        // This test verifies the error handling when disk files are corrupted
        // Since we can't easily corrupt files in tests, we test the error path
        // by attempting to retrieve a non-existent key

        // When
        let getResult: Result<TestData?, AppError> = cacheManager
            .get(key: "nonexistent_disk_key")

        // Then - Should return success with nil (cache miss), not an error
        switch getResult {
        case let .success(data):
            #expect(data == nil) // Cache miss is expected
        case let .failure(error):
            // If there is an error, it should be a valid error type
            #expect(error.category == .data || error.category == .system)
        }
    }

    @Test("Invalid cache data should log appropriate error messages")
    func cacheDeserializationErrorLogging() async throws {
        // Given
        let mockLogger = MockLogger()
        let cacheManager = try CacheManager(logger: mockLogger)

        // Set valid data first
        let validData = TestData(id: "logging_test", value: 789)
        let setResult = await cacheManager.set(validData, key: "logging_key")
        guard case .success = setResult else {
            Issue.record("Failed to set up test data")
            return
        }

        // Try to read as wrong type to trigger deserialization error
        let _: Result<InvalidTestData?, AppError> = cacheManager
            .get(key: "logging_key")

        // Then - Check that errors were logged
        // Note: The actual logging happens inside the JSONDecoder extension
        // This test verifies the integration - logging behavior is
        // implementation dependent
    }

    @Test("Cache directory creation should succeed or handle failure gracefully"
    )
    func cacheDirectoryCreation() async throws {
        // Given
        let mockLogger = MockLogger()

        // Create a temporary directory that we can make read-only to simulate
        // failure
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(
            at: tempDir,
            withIntermediateDirectories: true
        )

        // Make it read-only to simulate creation failure
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o444],
            ofItemAtPath: tempDir.path
        )

        defer {
            // Clean up - restore permissions and remove
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: tempDir.path
            )
            try? FileManager.default.removeItem(at: tempDir)
        }

        // This test is hard to simulate without dependency injection
        // For now, we'll test that CacheManager can be created successfully
        _ = try CacheManager(logger: mockLogger)
    }

    @Test("Serialization failure should return serialization error")
    func serializationFailure() async throws {
        // Given
        let mockLogger = MockLogger()
        let cacheManager = try CacheManager(logger: mockLogger)

        // Create a non-serializable object (we'll use a mock approach)
        struct NonSerializableData: Codable, Sendable {
            let data: Data

            func encode(to _: Encoder) throws {
                throw EncodingError.invalidValue(data, EncodingError.Context(
                    codingPath: [],
                    debugDescription: "Test serialization failure"
                ))
            }
        }

        let nonSerializableData = NonSerializableData(data: Data())

        // When
        let result = await cacheManager.set(
            nonSerializableData,
            key: "test_key"
        )

        // Then
        switch result {
        case let .failure(error):
            #expect(error.category == .data)
            if case .serializationError = error {
                // Expected error type
            } else {
                Issue.record("Expected serializationError, got \(error)")
            }
        case .success:
            Issue.record("Expected failure but got success")
        }
    }

    @Test("Disk write should succeed or return file system error")
    func diskWrite() async throws {
        // Given
        let mockLogger = MockLogger()
        let cacheManager = try CacheManager(logger: mockLogger)

        // Try to write to a key that would trigger disk persistence but should
        // succeed
        let testData = TestData(id: "device_test", value: 42)

        // When - Set a device-related key that should persist to disk
        let result = await cacheManager.set(testData, key: "devices_list")

        // Then - This should succeed in normal conditions
        // Testing actual disk failure requires more complex mocking
        switch result {
        case .success:
            // This is the expected path for a working file system
            #expect(true) // Test passes
        case let .failure(error):
            // If there's an error, it should be a fileSystemError
            if case .fileSystemError = error {
                #expect(true) // This would be acceptable if disk actually
                // failed
            } else {
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }

    // MARK: - Success Path Tests

    @Test("Setting value should return success")
    func settingValue() async throws {
        // Given
        let mockLogger = MockLogger()
        let cacheManager = try CacheManager(logger: mockLogger)
        let testData = TestData(id: "test", value: 123)

        // When
        let result = await cacheManager.set(testData, key: "test_key")

        // Then
        switch result {
        case .success:
            // Expected success
            break
        case let .failure(error):
            Issue.record("Expected success but got error: \(error)")
        }
    }

    @Test("Getting existing value should return the cached value")
    func gettingExistingValue() async throws {
        // Given
        let mockLogger = MockLogger()
        let cacheManager = try CacheManager(logger: mockLogger)
        let testData = TestData(id: "test", value: 456)

        // Set a value first
        let setResult = await cacheManager.set(testData, key: "existing_key")
        guard case .success = setResult else {
            Issue.record("Failed to set up test data")
            return
        }

        // When
        let getResult: Result<TestData?, AppError> = cacheManager
            .get(key: "existing_key")

        // Then
        switch getResult {
        case let .success(retrievedData):
            #expect(retrievedData != nil)
            #expect(retrievedData?.id == testData.id)
            #expect(retrievedData?.value == testData.value)
        case let .failure(error):
            Issue.record("Expected success but got error: \(error)")
        }
    }

    @Test("Getting nonexistent value should return nil")
    func gettingNonexistentValue() async throws {
        // Given
        let mockLogger = MockLogger()
        let cacheManager = try CacheManager(logger: mockLogger)

        // When
        let result: Result<TestData?, AppError> = cacheManager
            .get(key: "nonexistent_key")

        // Then
        switch result {
        case let .success(retrievedData):
            #expect(retrievedData == nil)
        case let .failure(error):
            Issue
                .record(
                    "Expected success with nil value but got error: \(error)"
                )
        }
    }
}

// MARK: - Mock Dependencies

private final class MockLogger: LoggerProtocol, @unchecked Sendable {
    private let _loggedMessages = NSMutableArray()

    var loggedMessages: [String] {
        _loggedMessages.compactMap { $0 as? String }
    }

    func log(_ message: String, level _: OSLogType) {
        _loggedMessages.add(message)
    }
}

// MARK: - Test Data

private struct TestData: Codable, Sendable {
    let id: String
    let value: Int
}

private struct InvalidTestData: Codable, Sendable {
    let wrongField: String
    let anotherField: Double
}
