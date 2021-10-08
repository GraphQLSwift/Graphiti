import Foundation

@available(*, deprecated, message: "Use `Coders` with `.format()` or `.iso8601` options instead")
public protocol DateFormatter {
    func date(from string: String) -> Date?
    func string(from date: Date) -> String
}

extension Foundation.DateFormatter : DateFormatter {}
@available(OSX 10.12, *)
extension Foundation.ISO8601DateFormatter : DateFormatter {}
