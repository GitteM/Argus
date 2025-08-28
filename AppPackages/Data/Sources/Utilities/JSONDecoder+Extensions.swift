import Foundation
import ServiceProtocols

public extension JSONDecoder {
    /// Decode MQTT data with proper error logging instead of fatal errors
    func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        logger: LoggerProtocol,
        context: String = ""
    ) -> T? {
        do {
            return try decode(T.self, from: data)
        } catch let DecodingError.keyNotFound(key, context) {
            let message =
                """
                Failed to decode \(type) \(context) - missing key
                '\(key.stringValue)': \(context.debugDescription)
                """
            logger.log(message, level: .error)
            return nil
        } catch let DecodingError.typeMismatch(_, context) {
            let message =
                """
                "Failed to decode \(type) \(context)
                type mismatch: \(context.debugDescription)
                """
            logger.log(message, level: .error)
            return nil
        } catch let DecodingError.valueNotFound(type, context) {
            let message =
                """
                Failed to decode \(type) \(context)
                missing \(type)
                value: \(context.debugDescription)
                """
            logger.log(message, level: .error)
            return nil
        } catch let DecodingError.dataCorrupted(context) {
            let message =
                """
                Failed to decode \(type) \(context)
                data corrupted: \(context.debugDescription)
                """
            logger.log(message, level: .error)
            return nil
        } catch {
            let message =
                """
                Failed to decode \(type) \(context)
                Error: \(error.localizedDescription)
                """
            logger.log(message, level: .error)
            return nil
        }
    }
}
