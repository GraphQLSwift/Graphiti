import Foundation

public protocol FederationEntityKey: Codable {}

public protocol FederationEntity: Codable {
    static var typename: String { get }
}

public extension FederationEntity {
    static var typename: String { Reflection.name(for: Self.self) }
}
