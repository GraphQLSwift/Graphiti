import GraphQL

public protocol InputType  : MapInitializable {}
public protocol OutputType : MapFallibleRepresentable {}

public protocol Arguments : MapInitializable {
    static var descriptions: [String: String] { get }
    static var defaultValues: [String: MapRepresentable] { get }
}

extension Arguments {
    public static var descriptions: [String: String] {
        return [:]
    }

    public static var defaultValues: [String: MapRepresentable] {
        return [:]
    }
}

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
        let arguments = try schema.arguments(type: A.self, field: name)

        let field = GraphQLField(
            type: try schema.getOutputType(from: (O?).self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: arguments,
            resolve: resolve.map { resolve in
                return { source, args, context, info in
                    guard let s = source as? Type else {
                        throw GraphQLError(message: "Expected type \(Type.self) but got \(type(of: source))")
                    }

                    let a = try A(map: args)

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
        let arguments = try schema.arguments(type: A.self, field: name)

        let field = GraphQLField(
            type: try schema.getOutputType(from: O.self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: arguments,
            resolve: resolve.map { resolve in
                return { source, args, context, info in
                    guard let s = source as? Type else {
                        throw GraphQLError(message: "Expected type \(Type.self) but got \(type(of: source))")
                    }

                    let a = try A(map: args)
                    return try resolve(s, a, context, info)
                }
            }
        )
        
        fields[name] = field
    }
}
