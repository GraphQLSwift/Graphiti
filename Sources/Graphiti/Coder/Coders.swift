import Foundation
import GraphQL

/// Struct containing a MapEncoder and MapDecoder. These decoders are passed through to the Schema objects and used in
/// all encoding and decoding from maps.
public struct Coders {
    public let decoder = MapDecoder()
    public let encoder = MapEncoder()

    public init() {}
}
