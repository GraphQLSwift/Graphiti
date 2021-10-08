import GraphQL
import Foundation

/// Struct containing a MapEncoder and MapDecoder. These decoders are passed through to the Schema objects and used in
/// all encoding and decoding from maps.
public struct Coders {
    let decoder = MapDecoder()
    let encoder = MapEncoder()
    
    public init() { }
}
