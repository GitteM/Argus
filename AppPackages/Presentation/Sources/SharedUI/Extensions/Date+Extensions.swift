import Foundation

public extension Date {
    var abbreviatedDateTime: String {
        formatted(date: .abbreviated, time: .shortened)
    }

    var shortDateTime: String {
        formatted(date: .numeric, time: .shortened)
    }

    var timeOnly: String {
        formatted(date: .omitted, time: .shortened)
    }

    var dateOnly: String {
        formatted(date: .abbreviated, time: .omitted)
    }
}
