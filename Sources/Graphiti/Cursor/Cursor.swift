import Foundation

public protocol HasCustomCursor {
    associatedtype Cursor: CursorType
    func cursor() -> Cursor
}

public protocol CursorType: Codable {
    init?(base64EncodedString: String)
    func base64Encoded() throws -> String
}

public extension CursorType {
    init?(base64EncodedString: String) {
        guard let data = base64EncodedString.data(using: .utf8) else {
            return nil
        }
        let decoder = JSONDecoder()
        guard let cursor = try? decoder.decode(Self.self, from: data) else {
            return nil
        }
        self = cursor
    }
    
    func base64Encoded() throws -> String {
        let encoder = JSONEncoder()
        return try encoder.encode(self).base64EncodedString()
    }
}
