import Entities
import Foundation
import ServiceProtocols

public extension JSONDecoder {
    func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        logger: LoggerProtocol,
        context: String = ""
    ) throws -> T {
        do {
            return try decode(T.self, from: data)
        } catch let DecodingError.keyNotFound(key, decodingContext) {
            let details =
                """
                Missing key '\(key.stringValue)': \(decodingContext
                    .debugDescription
                )
                """
            logger.log(
                "Failed to decode \(type) \(context) - \(details)",
                level: .error
            )
            throw AppError.deserializationError(
                type: String(describing: type),
                details: details
            )
        } catch let DecodingError.typeMismatch(_, decodingContext) {
            let details =
                """
                Type mismatch: \(decodingContext.debugDescription)
                """
            logger.log(
                "Failed to decode \(type) \(context) - \(details)",
                level: .error
            )
            throw AppError.deserializationError(
                type: String(describing: type),
                details: details
            )
        } catch let DecodingError.valueNotFound(valueType, decodingContext) {
            let details =
                """
                Missing \(valueType) value: \(decodingContext.debugDescription)
                """
            logger.log(
                "Failed to decode \(type) \(context) - \(details)",
                level: .error
            )
            throw AppError.deserializationError(
                type: String(describing: type),
                details: details
            )
        } catch let DecodingError.dataCorrupted(decodingContext) {
            let details =
                """
                Data corrupted: \(decodingContext.debugDescription)
                """
            logger.log(
                "Failed to decode \(type) \(context) - \(details)",
                level: .error
            )
            throw AppError.deserializationError(
                type: String(describing: type),
                details: details
            )
        } catch {
            let details = error.localizedDescription
            logger.log(
                "Failed to decode \(type) \(context) - \(details)",
                level: .error
            )
            throw AppError.deserializationError(
                type: String(describing: type),
                details: details
            )
        }
    }
}
