import Foundation
@testable import Graphiti
import GraphQL
import XCTest

class UnionTests: XCTestCase {
    func testUnionInit() throws {
        _ = try Schema<StarWarsResolver, StarWarsContext> {
            Type(Planet.self) {
                Field("id", at: \.id)
            }

            Type(Human.self) {
                Field("id", at: \.id)
            }

            Type(Droid.self) {
                Field("id", at: \.id)
            }

            Union(SearchResult.self, members: Planet.self, Human.self, Droid.self)

            Query {
                Field("search", at: StarWarsResolver.search) {
                    Argument("query", at: \.query)
                }
            }
        }

        _ = try Schema<StarWarsResolver, StarWarsContext> {
            Type(Planet.self) {
                Field("id", at: \.id)
            }

            Type(Human.self) {
                Field("id", at: \.id)
            }

            Type(Droid.self) {
                Field("id", at: \.id)
            }

            Union(SearchResult.self, members: [
                Planet.self,
                Human.self,
                Droid.self,
            ])

            Query {
                Field("search", at: StarWarsResolver.search) {
                    Argument("query", at: \.query)
                }
            }
        }
    }
}
