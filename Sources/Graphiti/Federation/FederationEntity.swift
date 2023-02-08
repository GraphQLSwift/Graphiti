import Foundation

public protocol FederationEntityKey: Codable {
    static var fields: String { get }
}

public protocol FederationEntity: Codable {
    static var typename: String { get }
}

public extension FederationEntity {
    static var typename: String { Reflection.name(for: Self.self) }
}
