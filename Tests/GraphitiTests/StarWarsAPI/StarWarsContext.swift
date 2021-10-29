/**
 * This defines a basic set of data for our Star Wars Schema.
 *
 * This data is hard coded for the sake of the demo, but you could imagine
 * fetching this data from a backend service rather than from hardcoded
 * values in a more complex demo.
 */
@available(macOS 12.0.0, *)
public actor StarWarsContext {
    private static var tatooine = Planet(
        id:"10001",
        name: "Tatooine",
        diameter: 10465,
        rotationPeriod: 23,
        orbitalPeriod: 304,
        residents: []
    )
    
    private static var alderaan = Planet(
        id: "10002",
        name: "Alderaan",
        diameter: 12500,
        rotationPeriod: 24,
        orbitalPeriod: 364,
        residents: []
    )
    
    private static var planetData: [String: Planet] = [
        "10001": tatooine,
        "10002": alderaan,
    ]
    
    private static var luke = Human(
        id: "1000",
        name: "Luke Skywalker",
        friends: ["1002", "1003", "2000", "2001"],
        appearsIn: [.newHope, .empire, .jedi],
        homePlanet: tatooine
    )
    
    private static var vader = Human(
        id: "1001",
        name: "Darth Vader",
        friends: [ "1004" ],
        appearsIn: [.newHope, .empire, .jedi],
        homePlanet: tatooine
    )
    
    private static var han = Human(
        id: "1002",
        name: "Han Solo",
        friends: ["1000", "1003", "2001"],
        appearsIn: [.newHope, .empire, .jedi],
        homePlanet: alderaan
    )
    
    private static var leia = Human(
        id: "1003",
        name: "Leia Organa",
        friends: ["1000", "1002", "2000", "2001"],
        appearsIn: [.newHope, .empire, .jedi],
        homePlanet: alderaan
    )
    
    private static var tarkin = Human(
        id: "1004",
        name: "Wilhuff Tarkin",
        friends: ["1001"],
        appearsIn: [.newHope],
        homePlanet: alderaan
    )
    
    private static var humanData: [String: Human] = [
        "1000": luke,
        "1001": vader,
        "1002": han,
        "1003": leia,
        "1004": tarkin,
    ]
    
    private static var c3po = Droid(
        id: "2000",
        name: "C-3PO",
        friends: ["1000", "1002", "1003", "2001"],
        appearsIn: [.newHope, .empire, .jedi],
        primaryFunction: "Protocol"
    )
    
    private static var r2d2 = Droid(
        id: "2001",
        name: "R2-D2",
        friends: [ "1000", "1002", "1003" ],
        appearsIn: [.newHope, .empire, .jedi],
        primaryFunction: "Astromech"
    )
    
    private static var droidData: [String: Droid] = [
        "2000": c3po,
        "2001": r2d2,
    ]
    
    /**
     * Helper function to get a character by ID.
     */
    public func getCharacter(id: String) -> Character? {
        Self.humanData[id] ?? Self.droidData[id]
    }
    
    /**
     * Allows us to query for a character"s friends.
     */
    public func getFriends(of character: Character) -> [Character] {
        character.friends.compactMap { id in
            getCharacter(id: id)
        }
    }
    
    /**
     * Allows us to fetch the undisputed hero of the Star Wars trilogy, R2-D2.
     */
    public func getHero(of episode: Episode?) -> Character {
        if episode == .empire {
            // Luke is the hero of Episode V.
            return Self.luke
        }
        // R2-D2 is the hero otherwise.
        return Self.r2d2
    }
    
    /**
     * Allows us to query for the human with the given id.
     */
    public func getHuman(id: String) -> Human? {
        Self.humanData[id]
    }
    
    /**
     * Allows us to query for the droid with the given id.
     */
    public func getDroid(id: String) -> Droid? {
        Self.droidData[id]
    }
    
    /**
     * Allows us to get the secret backstory, or not.
     */
    public func getSecretBackStory() throws -> String? {
        struct Secret: Error, CustomStringConvertible {
            let description: String
        }
        
        throw Secret(description: "secretBackstory is secret.")
    }
    
    /**
     * Allows us to query for a Planet.
     */
    public func getPlanets(query: String) -> [Planet] {
        Self.planetData
            .sorted(by: { $0.key < $1.key })
            .map({ $1 })
            .filter({ $0.name.lowercased().contains(query.lowercased()) })
    }
    
    /**
     * Allows us to query for a Human.
     */
    public func getHumans(query: String) -> [Human] {
        Self.humanData
            .sorted(by: { $0.key < $1.key })
            .map({ $1 })
            .filter({ $0.name.lowercased().contains(query.lowercased()) })
    }
    
    /**
     * Allows us to query for a Droid.
     */
    public func getDroids(query: String) -> [Droid] {
        Self.droidData
            .sorted(by: { $0.key < $1.key })
            .map({ $1 })
            .filter({ $0.name.lowercased().contains(query.lowercased()) })
    }

    /**
     * Allows us to query for either a Human, Droid, or Planet.
     */
    public func search(query: String) -> [SearchResult] {
        getPlanets(query: query) + getHumans(query: query) + getDroids(query: query)
    }
}

@available(macOS 12.0.0, *)
public extension StarWarsContext {
    static let live = StarWarsContext()
}
