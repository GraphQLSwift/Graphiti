/**
 * This defines a basic set of data for our Star Wars Schema.
 *
 * This data is hard coded for the sake of the demo, but you could imagine
 * fetching this data from a backend service rather than from hardcoded
 * values in a more complex demo.
 */
final class StarWarsStore {
    lazy var tatooine = Planet(
        id:"10001",
        name: "Tatooine",
        diameter: 10465,
        rotationPeriod: 23,
        orbitalPeriod: 304,
        residents: []
    )
    
    lazy var alderaan = Planet(
        id: "10002",
        name: "Alderaan",
        diameter: 12500,
        rotationPeriod: 24,
        orbitalPeriod: 364,
        residents: []
    )
    
    lazy var planetData: [String: Planet] = [
        "10001": tatooine,
        "10002": alderaan,
    ]
    
    lazy var luke = Human(
        id: "1000",
        name: "Luke Skywalker",
        friends: ["1002", "1003", "2000", "2001"],
        appearsIn: [.newHope, .empire, .jedi],
        homePlanet: tatooine
    )
    
    lazy var vader = Human(
        id: "1001",
        name: "Darth Vader",
        friends: [ "1004" ],
        appearsIn: [.newHope, .empire, .jedi],
        homePlanet: tatooine
    )
    
    lazy var han = Human(
        id: "1002",
        name: "Han Solo",
        friends: ["1000", "1003", "2001"],
        appearsIn: [.newHope, .empire, .jedi],
        homePlanet: alderaan
    )
    
    lazy var leia = Human(
        id: "1003",
        name: "Leia Organa",
        friends: ["1000", "1002", "2000", "2001"],
        appearsIn: [.newHope, .empire, .jedi],
        homePlanet: alderaan
    )
    
    lazy var tarkin = Human(
        id: "1004",
        name: "Wilhuff Tarkin",
        friends: ["1001"],
        appearsIn: [.newHope],
        homePlanet: alderaan
    )
    
    lazy var humanData: [String: Human] = [
        "1000": luke,
        "1001": vader,
        "1002": han,
        "1003": leia,
        "1004": tarkin,
    ]
    
    lazy var c3po = Droid(
        id: "2000",
        name: "C-3PO",
        friends: ["1000", "1002", "1003", "2001"],
        appearsIn: [.newHope, .empire, .jedi],
        primaryFunction: "Protocol"
    )
    
    lazy var r2d2 = Droid(
        id: "2001",
        name: "R2-D2",
        friends: [ "1000", "1002", "1003" ],
        appearsIn: [.newHope, .empire, .jedi],
        primaryFunction: "Astromech"
    )
    
    lazy var droidData: [String: Droid] = [
        "2000": c3po,
        "2001": r2d2,
    ]
    
    /**
     * Helper function to get a character by ID.
     */
    func getCharacter(id: String) -> Character? {
        humanData[id] ?? droidData[id]
    }
    
    /**
     * Allows us to query for a character"s friends.
     */
    func getFriends(of character: Character) -> [Character] {
        character.friends.compactMap { id in
            getCharacter(id: id)
        }
    }
    
    /**
     * Allows us to fetch the undisputed hero of the Star Wars trilogy, R2-D2.
     */
    func getHero(of episode: Episode?) -> Character {
        if episode == .empire {
            // Luke is the hero of Episode V.
            return luke
        }
        // R2-D2 is the hero otherwise.
        return r2d2
    }
    
    /**
     * Allows us to query for the human with the given id.
     */
    func getHuman(id: String) -> Human? {
        humanData[id]
    }
    
    /**
     * Allows us to query for the droid with the given id.
     */
    func getDroid(id: String) -> Droid? {
        droidData[id]
    }
    
    /**
     * Allows us to get the secret backstory, or not.
     */
    func getSecretBackStory() throws -> String? {
        struct Secret : Error, CustomStringConvertible {
            let description: String
        }
        
        throw Secret(description: "secretBackstory is secret.")
    }
    
    /**
     * Allows us to query for a Planet.
     */
    func getPlanets(query: String) -> [Planet] {
        planetData
            .sorted(by: { $0.key < $1.key })
            .map({ $1 })
            .filter({ $0.name.lowercased().contains(query.lowercased()) })
    }
    
    /**
     * Allows us to query for a Human.
     */
    func getHumans(query: String) -> [Human] {
        humanData
            .sorted(by: { $0.key < $1.key })
            .map({ $1 })
            .filter({ $0.name.lowercased().contains(query.lowercased()) })
    }
    
    /**
     * Allows us to query for a Droid.
     */
    func getDroids(query: String) -> [Droid] {
        droidData
            .sorted(by: { $0.key < $1.key })
            .map({ $1 })
            .filter({ $0.name.lowercased().contains(query.lowercased()) })
    }

    /**
     * Allows us to query for either a Human, Droid, or Planet.
     */
    func search(query: String) -> [SearchResult] {
        return getPlanets(query: query) + getHumans(query: query) + getDroids(query: query)
    }
}
