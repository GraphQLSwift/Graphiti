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

/**
 * Using our shorthand to describe type systems, the type system for our
 * Star Wars example is:
 *
 *     enum Episode { NEWHOPE, EMPIRE, JEDI }
 *
 *     interface Character {
 *         id: String!
 *         name: String
 *         friends: [Character]
 *         appearsIn: [Episode]
 *         secretBackstory: String
 *     }
 *
 *     type Human : Character {
 *         id: String!
 *         name: String
 *         friends: [Character]
 *         appearsIn: [Episode]
 *         secretBackstory: String
 *         homePlanet: String
 *     }
 *
 *     type Droid : Character {
 *         id: String!
 *         name: String
 *         friends: [Character]
 *         appearsIn: [Episode]
 *         secretBackstory: String
 *         primaryFunction: String
 *     }
 *
 *     type Query {
 *         hero(episode: Episode): Character
 *         human(id: String!): Human
 *         droid(id: String!): Droid
 *     }
 */
let starWarsSchema = try! Schema<Void> { schema in
    /**
     * The original trilogy consists of three movies.
     *
     * This implements the following type system shorthand:
     *
     *     enum Episode { NEWHOPE, EMPIRE, JEDI }
     */
    try EnumType<Episode> { episode in
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
     *         name: String
     *         friends: [Character]
     *         appearsIn: [Episode]
     *         secretBackstory: String
     *     }
     */
    try InterfaceType<Character> { character in
        character.description = "A character in the Star Wars Trilogy"

        try character.field(
            name: "id",
            type: String.self,
            description: "The id of the character."
        )

        try character.field(
            name: "name",
            type: (String?).self,
            description: "The name of the character."
        )

        try character.field(
            name: "friends",
            type: [TypeReference<Character>?].self,
            description: "The friends of the character, or an empty list if they have none."
        )

        try character.field(
            name: "appearsIn",
            type: [Episode?].self,
            description: "Which movies they appear in."
        )

        try character.field(
            name: "secretBackstory",
            type: (String?).self,
            description: "All secrets about their past."
        )

        character.resolveType { character, _, _ in
            switch character {
            case is Human:
                return Human.self
            default:
                return Droid.self
            }
        }
    }

    /**
     * We define our human type, which implements the character interface.
     *
     * This implements the following type system shorthand:
     *
     *     type Human : Character {
     *         id: String!
     *         name: String
     *         friends: [Character]
     *         appearsIn: [Episode]
     *         secretBackstory: String
     *         homePlanet: String
     *     }
     */
    try ObjectType<Human>(interfaces: Character.self) { human in
        human.description = "A humanoid creature in the Star Wars universe."

        try human.field(
            name: "id",
            type: String.self,
            description: "The id of the human."
        )

        try human.field(
            name: "name",
            type: (String?).self,
            description: "The name of the human."
        )

        try human.field(
            name: "friends",
            type: [Character?].self,
            description: "The friends of the human, or an empty list if they have none.",
            resolve: { human, _, _, _ in
                getFriends(character: human)
            }
        )

        try human.field(
            name: "appearsIn",
            type: [Episode?].self,
            description: "Which movies they appear in."
        )

        try human.field(
            name: "homePlanet",
            type: (String?).self,
            description: "The home planet of the human, or null if unknown."
        )

        try human.field(
            name: "secretBackstory",
            type: (String?).self,
            description: "Where are they from and how they came to be who they are.",
            resolve: { _ in
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
     *         name: String
     *         friends: [Character]
     *         appearsIn: [Episode]
     *         secretBackstory: String
     *         primaryFunction: String
     *     }
     */
    try ObjectType<Droid>(interfaces: Character.self) { droid in
        droid.description = "A mechanical creature in the Star Wars universe."

        try droid.field(
            name: "id",
            type: String.self,
            description: "The id of the droid."
        )

        try droid.field(
            name: "name",
            type: (String?).self,
            description: "The name of the droid."
        )

        try droid.field(
            name: "friends",
            type: [Character?].self,
            description: "The friends of the droid, or an empty list if they have none.",
            resolve: { droid, _, _, _ in
                getFriends(character: droid)
            }
        )

        try droid.field(
            name: "appearsIn",
            type: [Episode?].self,
            description: "Which movies they appear in."
        )

        try droid.field(
            name: "secretBackstory",
            type: (String?).self,
            description: "Where are they from and how they came to be who they are.",
            resolve: { _ in
                try getSecretBackStory()
            }
        )

        try droid.field(
            name: "primaryFunction",
            type: (String?).self,
            description: "The primary function of the droid."
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
    schema.query = try ObjectType(name: "Query") { query in
        struct EpisodeArgument : Argument {
            let value: Episode?
            static let defaultValue: DefaultValue? = nil
            static let description: String? =
                "If omitted, returns the hero of the whole saga. If " +
                "provided, returns the hero of that particular episode."
        }

        struct HeroArguments : Arguments {
            let episode: EpisodeArgument
        }

        try query.field(name: "hero") { (_, arguments: HeroArguments, _, _) in
            getHero(episode: arguments.episode.value)
        }

        struct HumanIDArgument : Argument {
            let value: String
            static let defaultValue: DefaultValue? = nil
            static let description: String? = "id of the human"
        }

        struct HumanArguments : Arguments {
            let id: HumanIDArgument
        }

        try query.field(name: "human") { (_, arguments: HumanArguments, _, _) in
            getHuman(id: arguments.id.value)
        }

        struct DroidIDArgument : Argument {
            let value: String
            static let defaultValue: DefaultValue? = nil
            static let description: String? = "id of the droid"
        }

        struct DroidArguments : Arguments {
            let id: DroidIDArgument
        }

        try query.field(name: "droid") { (_, arguments: DroidArguments, _, _) in
            getDroid(id: arguments.id.value)
        }
    }

    schema.types = [Human.self, Droid.self]
}
