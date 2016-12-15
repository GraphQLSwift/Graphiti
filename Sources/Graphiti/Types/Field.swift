import GraphQL

public protocol InputType  : MapInitializable {}
public protocol OutputType : MapFallibleRepresentable {}

public typealias DefaultValue = MapRepresentable

public protocol ArgumentInfo {
    static var defaultValue: DefaultValue? { get }
    static var description: String? { get }
}

public protocol Arguments : MapInitializable {}
public protocol Argument  : MapInitializable, ArgumentInfo {}

public struct NoArguments : Arguments {
    init() {}
    public init(map: Map) throws {}
}

public typealias ResolveField<S, A : Arguments, R> = (
    _ source: S,
    _ args: A,
    _ context: Any,
    _ info: GraphQLResolveInfo
) throws -> R

public class FieldBuilder<Root, Type> {
    var schema: SchemaBuilder<Root>

    init(schema: SchemaBuilder<Root>) {
        self.schema = schema
    }

    var fields: GraphQLFieldMap = [:]

    func addAllFields() throws {
        for property in try properties(Type.self) {
            let field = GraphQLField(
                type: try schema.getOutputType(from: property.type, field: property.key)
            )

            fields[property.key] = field
        }
    }

    public func field<O>(
        name: String,
        type: (TypeReference<O>?).Type = (TypeReference<O>?).self,
        description: String? = nil,
        deprecationReason: String? = nil,
        resolve: ResolveField<Type, NoArguments, O?>? = nil
    ) throws {
        var r: GraphQLFieldResolve? = nil

        if let resolve = resolve {
            r = { source, _, context, info in
                guard let s = source as? Type else {
                    throw GraphQLError(message: "Expected type \(Type.self) but got \(type(of: source))")
                }

                guard let output = try resolve(s, NoArguments(), context, info) else {
                    return nil
                }

                return output
            }
        }

        let field = GraphQLField(
            type: try schema.getOutputType(from: (TypeReference<O>?).self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: [:],
            resolve: r
        )

        fields[name] = field
    }

    public func field<O>(
        name: String,
        type: TypeReference<O>.Type = TypeReference<O>.self,
        description: String? = nil,
        deprecationReason: String? = nil,
        resolve: ResolveField<Type, NoArguments, O>? = nil
    ) throws {
        var r: GraphQLFieldResolve? = nil

        if let resolve = resolve {
            r = { source, _, context, info in
                guard let s = source as? Type else {
                    throw GraphQLError(message: "Expected type \(Type.self) but got \(type(of: source))")
                }

                return try resolve(s, NoArguments(), context, info)
            }
        }

        let field = GraphQLField(
            type: try schema.getOutputType(from: TypeReference<O>.self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: [:],
            resolve: r
        )

        fields[name] = field
    }

    public func field<O>(
        name: String,
        type: [TypeReference<O>].Type = [TypeReference<O>].self,
        description: String? = nil,
        deprecationReason: String? = nil,
        resolve: ResolveField<Type, NoArguments, [O]>? = nil
    ) throws {
        var r: GraphQLFieldResolve? = nil

        if let resolve = resolve {
            r = { source, _, context, info in
                guard let s = source as? Type else {
                    throw GraphQLError(message: "Expected type \(Type.self) but got \(type(of: source))")
                }

                return try resolve(s, NoArguments(), context, info)
            }
        }

        let field = GraphQLField(
            type: try schema.getOutputType(from: [TypeReference<O>].self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: [:],
            resolve: r
        )

        fields[name] = field
    }

    public func field<O>(
        name: String,
        type: [TypeReference<O>].Type = [TypeReference<O>].self,
        description: String? = nil,
        deprecationReason: String? = nil
    ) throws {
        let field = GraphQLField(
            type: try schema.getOutputType(from: [TypeReference<O>].self, field: name),
            description: description,
            deprecationReason: deprecationReason
        )
        
        fields[name] = field
    }

    public func field<O>(
        name: String,
        type: O.Type = O.self,
        description: String? = nil,
        deprecationReason: String? = nil,
        resolve: ResolveField<Type, NoArguments, O>? = nil
    ) throws {
        var r: GraphQLFieldResolve? = nil

        if let resolve = resolve {
            r = { source, _, context, info in
                guard let s = source as? Type else {
                    throw GraphQLError(message: "Expected type \(Type.self) but got \(type(of: source))")
                }

                return try resolve(s, NoArguments(), context, info)
            }
        }

        let field = GraphQLField(
            type: try schema.getOutputType(from: O.self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: [:],
            resolve: r
        )

        fields[name] = field
    }

    public func field<A : Arguments, O>(
        name: String,
        type: (O?).Type = (O?).self,
        description: String? = nil,
        deprecationReason: String? = nil,
        resolve: ResolveField<Type, A, O?>? = nil
    ) throws {
        let (args, argumentInfoMap) = try schema.arguments(
            type: A.self,
            field: name
        )

        let field = GraphQLField(
            type: try schema.getOutputType(from: (O?).self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: args,
            resolve: resolve.map { resolve in
                return { source, args, context, info in
                    guard let s = source as? Type else {
                        throw GraphQLError(message: "Expected type \(Type.self) but got \(type(of: source))")
                    }

                    var dict = args.dictionary!

                    for (key, _) in argumentInfoMap {
                        if let value = dict[key] {
                            dict[key] = ["value": value]
                        } else {
                            dict[key] = ["value": .null]
                        }
                    }

                    let a = try A(map: dict.map)

                    guard let output = try resolve(s, a, context, info) else {
                        return nil
                    }

                    return output
                }
            }
        )

        fields[name] = field
    }

    public func field<A : Arguments, O>(
        name: String,
        type: O.Type = O.self,
        description: String? = nil,
        deprecationReason: String? = nil,
        resolve: ResolveField<Type, A, O>? = nil
    ) throws {
        let (args, argumentInfoMap) = try schema.arguments(
            type: A.self,
            field: name
        )

        let field = GraphQLField(
            type: try schema.getOutputType(from: O.self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: args,
            resolve: resolve.map { resolve in
                return { source, args, context, info in
                    guard let s = source as? Type else {
                        throw GraphQLError(message: "Expected type \(Type.self) but got \(type(of: source))")
                    }

                    var dict = args.dictionary!

                    for (key, _) in argumentInfoMap {
                        if let value = dict[key] {
                            dict[key] = ["value": value]
                        } else {
                            dict[key] = ["value": .null]
                        }
                    }
                    
                    let a = try A(map: dict.map)
                    return try resolve(s, a, context, info)
                }
            }
        )
        
        fields[name] = field
    }
}
