import Graphiti

/**
 * This is designed to be an end-to-end test, demonstrating
 * the full GraphQL stack.
 *
 * We will create a GraphQL schema that describes the major
 * characters in the original Star Wars trilogy.
 *
 * NOTE: This may contain spoilers for the original Star
 * Wars trilogy.
 */

extension Episode : InputType, OutputType {
    init(map: Map) throws {
        guard
            let name = map.string,
            let episode = Episode(rawValue: name)
            else {
                throw MapError.incompatibleType
        }

        self = episode
    }

    func asMap() throws -> Map {
        return rawValue.map
    }
}

extension Human : OutputType {}
extension Droid : OutputType {}
extension Planet: OutputType {}

/**
 * Using our shorthand to describe type systems, the type system for our
 * Star Wars example is:
 *
 *     enum Episode { NEWHOPE, EMPIRE, JEDI }
 *
 *     interface Character {
 *         id: String!
 *         name: String!
 *         friends: [Character!]!
 *         appearsIn: [Episode!]!
 *         secretBackstory: String
 *     }
 *
 *     type Human : Character {
 *         id: String!
 *         name: String!
 *         friends: [Character!]!
 *         appearsIn: [Episode!]!
 *         secretBackstory: String
 *         homePlanet: String!
 *     }
 *
 *     type Droid : Character {
 *         id: String!
 *         name: String!
 *         friends: [Character!]!
 *         appearsIn: [Episode!]!
 *         secretBackstory: String
 *         primaryFunction: String!
 *     }
 *
 *     type Query {
 *         hero(episode: Episode): Character
 *         human(id: String!): Human
 *         droid(id: String!): Droid
 *     }
 */

import GraphQL

let starWarsSchema = try! Schema<NoRoot, NoContext> { schema in
    /**
     * The original trilogy consists of three movies.
     *
     * This implements the following type system shorthand:
     *
     *     enum Episode { NEWHOPE, EMPIRE, JEDI }
     */
    try schema.enum(type: Episode.self) { episode in
        episode.description = "One of the films in the Star Wars Trilogy"

        try episode.value(
            name: "NEWHOPE",
            value: .newHope,
            description: "Released in 1977."
        )

        try episode.value(
            name: "EMPIRE",
            value: .empire,
            description: "Released in 1980."
        )

        try episode.value(
            name: "JEDI",
            value: .jedi,
            description: "Released in 1983."
        )
    }

    /**
     * Characters in the Star Wars trilogy are either humans or droids.
     *
     * This implements the following type system shorthand:
     *
     *     interface Character {
     *         id: String!
     *         name: String!
     *         friends: [Character!]!
     *         appearsIn: [Episode!]!
     *         secretBackstory: String
     *     }
     */
    try schema.interface(type: Character.self) { character in
        character.description = "A character in the Star Wars Trilogy"

        try character.field(
            name: "id",
            type: String.self,
            description: "The id of the character."
        )

        try character.field(
            name: "name",
            type: String.self,
            description: "The name of the character."
        )

        try character.field(
            name: "friends",
            type: [TypeReference<Character>].self,
            description: "The friends of the character, or an empty list if they have none."
        )

        try character.field(
            name: "appearsIn",
            type: [Episode].self,
            description: "Which movies they appear in."
        )

        try character.field(
            name: "secretBackstory",
            type: (String?).self,
            description: "All secrets about their past."
        )
    }

    /**
     * Planet in the Star Warts trilogy.
     *
     * This implements the following type system shorthand:
     *
     *     interface Planet {
     *         id: String!
     *         name: String!
     *         diameter: Int!
     *         rotationPeriod: Int!
     *         orbitalPeriod: Int!
     *         residents: [Human!]!
     *     }
     */
    try schema.object(type: Planet.self) { planet in
        planet.description = "A large mass, planet or planetoid in the Star Wars Universe, at the time of 0 ABY."

        try planet.exportFields(excluding:"residents")

        try planet.field(
            name: "residents",
            type: [TypeReference<Human>].self,
            description: "")

    }

    /**
     * We define our human type, which implements the character interface.
     *
     * This implements the following type system shorthand:
     *
     *     type Human : Character {
     *         id: String!
     *         name: String!
     *         friends: [Character!]!
     *         appearsIn: [Episode!]!
     *         secretBackstory: String
     *         homePlanet: Planet!
     *     }
     */
    try schema.object(type: Human.self, interfaces: Character.self) { human in
        human.description = "A humanoid creature in the Star Wars universe."

        try human.exportFields()

        try human.field(
            name: "friends",
            type: [Character].self,
            description: "The friends of the human, or an empty list if they have none.",
            resolve: { human, _, _, _ in
                getFriends(character: human)
            }
        )

        try human.field(
            name: "secretBackstory",
            type: (String?).self,
            description: "Where are they from and how they came to be who they are.",
            resolve: { _, _, _, _ in
                try getSecretBackStory()
            }
        )
    }

    /**
     * The other type of character in Star Wars is a droid.
     *
     * This implements the following type system shorthand:
     *
     *     type Droid : Character {
     *         id: String!
     *         name: String!
     *         friends: [Character!]!
     *         appearsIn: [Episode!]!
     *         secretBackstory: String
     *         primaryFunction: String!
     *     }
     */
    try schema.object(type: Droid.self, interfaces: Character.self) { droid in
        droid.description = "A mechanical creature in the Star Wars universe."

        try droid.exportFields()

        try droid.field(
            name: "friends",
            type: [Character].self,
            description: "The friends of the droid, or an empty list if they have none.",
            resolve: { droid, _, _, _ in
                getFriends(character: droid)
            }
        )

        try droid.field(
            name: "secretBackstory",
            type: (String?).self,
            description: "Where are they from and how they came to be who they are.",
            resolve: { _, _, _, _ in
                try getSecretBackStory()
            }
        )
    }

    /**
     * This is the type that will be the root of our query, and the
     * entry point into our schema. It gives us the ability to fetch
     * objects by their IDs, as well as to fetch the undisputed hero
     * of the Star Wars trilogy, R2-D2, directly.
     *
     * This implements the following type system shorthand:
     *
     *     type Query {
     *         hero(episode: Episode): Character
     *         human(id: String!): Human
     *         droid(id: String!): Droid
     *     }
     */
    try schema.query { query in
        struct HeroArguments : Arguments {
            let episode: Episode?

            static let descriptions = [
                "episode":
                    "If omitted, returns the hero of the whole saga. If " +
                    "provided, returns the hero of that particular episode."
            ]
        }

        try query.field(name: "hero") { (_, arguments: HeroArguments, _, _) in
            getHero(episode: arguments.episode)
        }

        struct HumanArguments : Arguments {
            let id: String
            static let descriptions = ["id": "id of the human"]
        }

        try query.field(name: "human") { (_, arguments: HumanArguments, _, _) in
            getHuman(id: arguments.id)
        }

        struct DroidArguments : Arguments {
            let id: String
            static let descriptions = ["id": "id of the droid"]
        }

        try query.field(name: "droid") { (_, arguments: DroidArguments, _, _) in
            getDroid(id: arguments.id)
        }
    }

    schema.types = [Human.self, Droid.self]
}
