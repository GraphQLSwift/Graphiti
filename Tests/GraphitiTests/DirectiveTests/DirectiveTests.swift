@testable import Graphiti
import GraphQL
import NIO
import XCTest

class DirectiveTests: XCTestCase {
    private let api = StarWarsAPI()
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    deinit {
        try? self.group.syncShutdownGracefully()
    }

    func testSkip() throws {
        let query = """
        query FetchHeroNameWithSkip($skipName: Boolean!) {
            hero {
                id
                name @skip(if: $skipName)
            }
        }
        """

        let input: [String: Map] = [
            "skipName": true,
        ]

        let response = try api.execute(
            request: query,
            context: StarWarsContext(),
            on: group,
            variables: input
        ).wait()

        let expected = GraphQLResult(
            data: [
                "hero": [
                    "id": "2001",
                ],
            ]
        )

        XCTAssertEqual(response, expected)
    }

    func testInclude() throws {
        let query = """
        query FetchHeroNameWithSkip($includeName: Boolean!) {
            hero {
                id
                name @include(if: $includeName)
            }
        }
        """

        let input: [String: Map] = [
            "includeName": false,
        ]

        let response = try api.execute(
            request: query,
            context: StarWarsContext(),
            on: group,
            variables: input
        ).wait()

        let expected = GraphQLResult(
            data: [
                "hero": [
                    "id": "2001",
                ],
            ]
        )

        XCTAssertEqual(response, expected)
    }
}
