import GraphQL

public protocol InputType  : MapInitializable {}
public protocol OutputType : MapFallibleRepresentable {}

public protocol Arguments : InputType {
    static var descriptions: [String: String] { get }
    static var defaultValues: [String: OutputType] { get }
}

extension Arguments {
    public static var descriptions: [String: String] {
        return [:]
    }

    public static var defaultValues: [String: OutputType] {
        return [:]
    }
}

public struct NoArguments : Arguments {
    init() {}
    public init(map: Map) throws {}
}

public typealias ResolveField<S, A : Arguments, C, R> = (
    _ source: S,
    _ args: A,
    _ context: C,
    _ info: GraphQLResolveInfo
) throws -> R

public class FieldBuilder<Root, Context, Type> {
    var schema: SchemaBuilder<Root, Context>

    init(schema: SchemaBuilder<Root, Context>) {
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

    public func field<Output>(
        name: String,
        type: (TypeReference<Output>?).Type = (TypeReference<Output>?).self,
        description: String? = nil,
        deprecationReason: String? = nil,
        resolve: ResolveField<Type, NoArguments, Context, Output?>? = nil
    ) throws {
        var r: GraphQLFieldResolve? = nil

        if let resolve = resolve {
            r = { source, _, context, info in
                guard let s = source as? Type else {
                    throw GraphQLError(message: "Expected source type \(Type.self) but got \(type(of: source))")
                }

                guard let c = context as? Context else {
                    throw GraphQLError(message: "Expected context type \(Context.self) but got \(type(of: context))")
                }

                guard let output = try resolve(s, NoArguments(), c, info) else {
                    return nil
                }

                return output
            }
        }

        let field = GraphQLField(
            type: try schema.getOutputType(from: (TypeReference<Output>?).self, field: name),
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
        resolve: ResolveField<Type, NoArguments, Context, O>? = nil
    ) throws {
        var r: GraphQLFieldResolve? = nil

        if let resolve = resolve {
            r = { source, _, context, info in
                guard let s = source as? Type else {
                    throw GraphQLError(message: "Expected source type \(Type.self) but got \(type(of: source))")
                }

                guard let c = context as? Context else {
                    throw GraphQLError(message: "Expected context type \(Context.self) but got \(type(of: context))")
                }

                return try resolve(s, NoArguments(), c, info)
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
        resolve: ResolveField<Type, NoArguments, Context, [O]>? = nil
    ) throws {
        var r: GraphQLFieldResolve? = nil

        if let resolve = resolve {
            r = { source, _, context, info in
                guard let s = source as? Type else {
                    throw GraphQLError(message: "Expected source type \(Type.self) but got \(type(of: source))")
                }

                guard let c = context as? Context else {
                    throw GraphQLError(message: "Expected context type \(Context.self) but got \(type(of: context))")
                }

                return try resolve(s, NoArguments(), c, info)
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
        resolve: ResolveField<Type, NoArguments, Context, O>? = nil
    ) throws {
        var r: GraphQLFieldResolve? = nil

        if let resolve = resolve {
            r = { source, _, context, info in
                guard let s = source as? Type else {
                    throw GraphQLError(message: "Expected source type \(Type.self) but got \(type(of: source))")
                }

                guard let c = context as? Context else {
                    throw GraphQLError(message: "Expected context type \(Context.self) but got \(type(of: context))")
                }

                return try resolve(s, NoArguments(), c, info)
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
        resolve: ResolveField<Type, A, Context, O?>? = nil
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
                        throw GraphQLError(message: "Expected source type \(Type.self) but got \(type(of: source))")
                    }

                    let a = try A(map: args)

                    guard let c = context as? Context else {
                        throw GraphQLError(message: "Expected context type \(Context.self) but got \(type(of: context))")
                    }

                    guard let output = try resolve(s, a, c, info) else {
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
        resolve: ResolveField<Type, A, Context, O>? = nil
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

                    guard let c = context as? Context else {
                        throw GraphQLError(message: "Expected context type \(Context.self) but got \(type(of: context))")
                    }

                    return try resolve(s, a, c, info)
                }
            }
        )
        
        fields[name] = field
    }
}
