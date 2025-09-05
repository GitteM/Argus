import DataUtilities
import Entities
import Foundation
import OSLog
import ServiceProtocols
import Testing

@Suite("JSONDecoder Extension Tests")
struct JSONDecoderExtensionTests {
    // MARK: - Success Path Tests

    @Test("Should successfully decode valid JSON")
    func successfulDecoding() throws {
        // Given
        let mockLogger = MockLogger()
        let decoder = JSONDecoder()
        let testData = TestModel(id: "test123", name: "Test Name", value: 42)
        let jsonData = try JSONEncoder().encode(testData)

        // When
        let decodedData: TestModel = try decoder.decode(
            TestModel.self,
            from: jsonData,
            logger: mockLogger,
            context: "test context"
        )

        // Then
        #expect(decodedData.id == testData.id)
        #expect(decodedData.name == testData.name)
        #expect(decodedData.value == testData.value)
        #expect(mockLogger.loggedMessages
            .isEmpty
        ) // No errors logged on success
    }

    @Test("Should log successful decoding without errors")
    func successfulDecodingLogging() throws {
        // Given
        let mockLogger = MockLogger()
        let decoder = JSONDecoder()
        let testData = TestModel(id: "log_test", name: "Log Test", value: 100)
        let jsonData = try JSONEncoder().encode(testData)

        // When
        let _: TestModel = try decoder.decode(
            TestModel.self,
            from: jsonData,
            logger: mockLogger,
            context: "logging test"
        )

        // Then
        #expect(mockLogger.loggedMessages.isEmpty)
    }

    // MARK: - Error Handling Tests

    @Test("Should throw AppError.deserializationError for missing required key")
    func missingRequiredKeyError() throws {
        // Given
        let mockLogger = MockLogger()
        let decoder = JSONDecoder()
        let incompleteJson = """
        {
            "id": "test123",
            "name": "Test Name"
            // Missing "value" field
        }
        """.data(using: .utf8)!

        // When & Then
        #expect(throws: AppError.self) {
            let _: TestModel = try decoder.decode(
                TestModel.self,
                from: incompleteJson,
                logger: mockLogger,
                context: "missing key test"
            )
        }

        // Verify error logging
        #expect(mockLogger.loggedMessages.count == 1)
        #expect(mockLogger.loggedMessages.first?
            .contains("Failed to decode") == true
        )
        #expect(mockLogger.loggedMessages.first?
            .contains("missing key test") == true
        )
    }

    @Test("Should throw correct AppError for missing key with details")
    func missingKeyErrorDetails() throws {
        // Given
        let mockLogger = MockLogger()
        let decoder = JSONDecoder()
        let incompleteJson = """
        {
            "id": "test123",
            "name": "Test Name"
        }
        """.data(using: .utf8)!

        // When
        do {
            let _: TestModel = try decoder.decode(
                TestModel.self,
                from: incompleteJson,
                logger: mockLogger,
                context: "error details test"
            )
            Issue.record("Expected error but decoding succeeded")
        } catch let error as AppError {
            // Then
            switch error {
            case let .deserializationError(type, details):
                #expect(type == "TestModel")
                #expect(details?.contains("Missing key 'value'") == true)
            default:
                Issue.record("Expected deserializationError, got \(error)")
            }
        }
    }

    @Test("Should throw AppError.deserializationError for type mismatch")
    func typeMismatchError() throws {
        // Given
        let mockLogger = MockLogger()
        let decoder = JSONDecoder()
        let wrongTypeJson = """
        {
            "id": "test123",
            "name": "Test Name",
            "value": "this_should_be_a_number"
        }
        """.data(using: .utf8)!

        // When & Then
        #expect(throws: AppError.self) {
            let _: TestModel = try decoder.decode(
                TestModel.self,
                from: wrongTypeJson,
                logger: mockLogger,
                context: "type mismatch test"
            )
        }

        // Verify error logging
        #expect(mockLogger.loggedMessages.count == 1)
        #expect(mockLogger.loggedMessages.first?
            .contains("Type mismatch") == true
        )
    }

    @Test("Should throw correct AppError for type mismatch with details")
    func typeMismatchErrorDetails() throws {
        // Given
        let mockLogger = MockLogger()
        let decoder = JSONDecoder()
        let wrongTypeJson = """
        {
            "id": "test123",
            "name": "Test Name",
            "value": "not_a_number"
        }
        """.data(using: .utf8)!

        // When
        do {
            let _: TestModel = try decoder.decode(
                TestModel.self,
                from: wrongTypeJson,
                logger: mockLogger,
                context: "type error details"
            )
            Issue.record("Expected error but decoding succeeded")
        } catch let error as AppError {
            // Then
            switch error {
            case let .deserializationError(type, details):
                #expect(type == "TestModel")
                #expect(details?.contains("Type mismatch") == true)
            default:
                Issue.record("Expected deserializationError, got \(error)")
            }
        }
    }

    @Test("Should throw AppError.deserializationError for corrupted data")
    func dataCorruptedError() throws {
        // Given
        let mockLogger = MockLogger()
        let decoder = JSONDecoder()
        let corruptedJson = "{ this is not valid json }".data(using: .utf8)!

        // When & Then
        #expect(throws: AppError.self) {
            let _: TestModel = try decoder.decode(
                TestModel.self,
                from: corruptedJson,
                logger: mockLogger,
                context: "corrupted data test"
            )
        }

        // Verify error logging
        #expect(mockLogger.loggedMessages.count == 1)
        #expect(mockLogger.loggedMessages.first?
            .contains("Failed to decode") == true
        )
    }

    @Test("Should throw AppError.deserializationError for empty data")
    func emptyDataError() throws {
        // Given
        let mockLogger = MockLogger()
        let decoder = JSONDecoder()
        let emptyData = Data()

        // When & Then
        #expect(throws: AppError.self) {
            let _: TestModel = try decoder.decode(
                TestModel.self,
                from: emptyData,
                logger: mockLogger,
                context: "empty data test"
            )
        }

        // Verify error logging
        #expect(mockLogger.loggedMessages.count == 1)
    }

    @Test("Should handle value not found error")
    func valueNotFoundError() throws {
        // Given
        let mockLogger = MockLogger()
        let decoder = JSONDecoder()
        let nullValueJson = """
        {
            "id": "test123",
            "name": "Test Name",
            "value": null
        }
        """.data(using: .utf8)!

        // When & Then
        #expect(throws: AppError.self) {
            let _: TestModel = try decoder.decode(
                TestModel.self,
                from: nullValueJson,
                logger: mockLogger,
                context: "null value test"
            )
        }

        // Verify error logging
        #expect(mockLogger.loggedMessages.count == 1)
        #expect(mockLogger.loggedMessages.first?.contains("Missing") == true)
    }

    // MARK: - Context and Logging Tests

    @Test("Should include context in error messages")
    func contextInErrorMessages() throws {
        // Given
        let mockLogger = MockLogger()
        let decoder = JSONDecoder()
        let invalidJson = "invalid".data(using: .utf8)!
        let testContext = "from MQTT message processing"

        // When
        do {
            let _: TestModel = try decoder.decode(
                TestModel.self,
                from: invalidJson,
                logger: mockLogger,
                context: testContext
            )
            Issue.record("Expected error but decoding succeeded")
        } catch {
            // Then
            #expect(mockLogger.loggedMessages.count == 1)
            #expect(mockLogger.loggedMessages.first?
                .contains(testContext) == true
            )
        }
    }

    @Test("Should work with empty context")
    func emptyContext() throws {
        // Given
        let mockLogger = MockLogger()
        let decoder = JSONDecoder()
        let invalidJson = "invalid".data(using: .utf8)!

        // When & Then
        #expect(throws: AppError.self) {
            let _: TestModel = try decoder.decode(
                TestModel.self,
                from: invalidJson,
                logger: mockLogger
                // No context parameter - should use default empty string
            )
        }

        // Verify it still logs errors
        #expect(mockLogger.loggedMessages.count == 1)
    }

    // MARK: - Complex Data Type Tests

    @Test("Should handle complex nested objects")
    func complexNestedObjects() throws {
        // Given
        let mockLogger = MockLogger()
        let decoder = JSONDecoder()
        let complexData = ComplexTestModel(
            header: TestModel(id: "header", name: "Header", value: 1),
            items: [
                TestModel(id: "item1", name: "Item 1", value: 10),
                TestModel(id: "item2", name: "Item 2", value: 20)
            ],
            metadata: ["key1": "value1", "key2": "value2"]
        )
        let jsonData = try JSONEncoder().encode(complexData)

        // When
        let decodedData: ComplexTestModel = try decoder.decode(
            ComplexTestModel.self,
            from: jsonData,
            logger: mockLogger,
            context: "complex object test"
        )

        // Then
        #expect(decodedData.header.id == complexData.header.id)
        #expect(decodedData.items.count == complexData.items.count)
        #expect(decodedData.metadata["key1"] == "value1")
        #expect(mockLogger.loggedMessages.isEmpty)
    }

    @Test("Should handle arrays correctly")
    func arrayDecoding() throws {
        // Given
        let mockLogger = MockLogger()
        let decoder = JSONDecoder()
        let testArray = [
            TestModel(id: "1", name: "First", value: 100),
            TestModel(id: "2", name: "Second", value: 200)
        ]
        let jsonData = try JSONEncoder().encode(testArray)

        // When
        let decodedArray: [TestModel] = try decoder.decode(
            [TestModel].self,
            from: jsonData,
            logger: mockLogger,
            context: "array test"
        )

        // Then
        #expect(decodedArray.count == 2)
        #expect(decodedArray[0].id == "1")
        #expect(decodedArray[1].id == "2")
        #expect(mockLogger.loggedMessages.isEmpty)
    }
}

// MARK: - Test Models

private struct TestModel: Codable, Equatable {
    let id: String
    let name: String
    let value: Int
}

private struct ComplexTestModel: Codable, Equatable {
    let header: TestModel
    let items: [TestModel]
    let metadata: [String: String]
}

// MARK: - Mock Logger

private final class MockLogger: LoggerProtocol, @unchecked Sendable {
    private let _loggedMessages = NSMutableArray()

    var loggedMessages: [String] {
        _loggedMessages.compactMap { $0 as? String }
    }

    func log(_ message: String, level _: OSLogType) {
        _loggedMessages.add(message)
    }
}
