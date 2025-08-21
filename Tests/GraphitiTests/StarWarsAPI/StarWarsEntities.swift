public enum Episode: String, CaseIterable, Codable, Sendable {
    case newHope = "NEWHOPE"
    case empire = "EMPIRE"
    case jedi = "JEDI"
}

public protocol Character: Sendable {
    var id: String { get }
    var name: String { get }
    var friends: [String] { get }
    var appearsIn: [Episode] { get }
}

public protocol SearchResult: Sendable {}

public struct Planet: SearchResult {
    public let id: String
    public let name: String
    public let diameter: Int
    public let rotationPeriod: Int
    public let orbitalPeriod: Int
    public var residents: [Human]
}

public struct Human: Character, SearchResult {
    public let id: String
    public let name: String
    public let friends: [String]
    public let appearsIn: [Episode]
    public let homePlanet: Planet
}

public struct Droid: Character, SearchResult {
    public let id: String
    public let name: String
    public let friends: [String]
    public let appearsIn: [Episode]
    public let primaryFunction: String
}
