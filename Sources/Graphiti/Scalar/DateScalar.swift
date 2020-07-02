import Foundation
import GraphQL

public final class DateScalar<RootType : Keyable, Context> : Scalar<RootType, Context, Date> {
    let formatter: Graphiti.DateFormatter
    
    public init(as name: String? = nil, formatter: Graphiti.DateFormatter) {
        self.formatter = formatter
        super.init(type: Date.self, name: name)
    }
    
    public override func serialize(scalar date: Date) throws -> Map {
        .string(formatter.string(from: date))
    }
    
    public override func parse(map: Map) throws -> Date {
        guard let string = map.string else {
            throw GraphQLError(message: "Invalid type for Date scalar. Expected string, but got \(map.typeDescription)")
        }
        
        guard let date = formatter.date(from: string) else {
            throw GraphQLError(message: "Invalid date string for Date scalar.")
        }
        
        return date
    }
}
