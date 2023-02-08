import Foundation

public struct FederationServiceType: Codable {
    public let sdl: String

    public init(sdl: String) {
        self.sdl = sdl
    }
}
