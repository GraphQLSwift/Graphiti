import GraphQL
import Runtime
import NIO

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

public typealias ResolveField<S, A : Arguments, C, E, R> = (
    _ source: S,
    _ args: A,
    _ context: C,
    _ eventLoopGroup: E,
    _ info: GraphQLResolveInfo
    ) throws -> R

public class FieldBuilder<Root, Context, EventLoop: EventLoopGroup, Type> {
    var schema: SchemaBuilder<Root, Context, EventLoop>

    init(schema: SchemaBuilder<Root, Context, EventLoop>) {
        self.schema = schema
    }

    var fields: GraphQLFieldMap = [:]


    /// Export all properties using reflection
    ///
    /// - Parameter excluding: properties excluded from the export
    /// - Throws: Reflection Errors
    public func exportFields(excluding: String...) throws {
        let info = try typeInfo(of: Type.self)

        for property in info.properties {
            if !excluding.contains(property.name) {
                let field = GraphQLField(type: try schema.getOutputType(from: property.type, field: property.name))
                fields[property.name] = field
            }
        }
    }

    public func field<Output>(
        name: String,
        type: (TypeReference<Output>?).Type = (TypeReference<Output>?).self,
        description: String? = nil,
        deprecationReason: String? = nil,
        resolve: ResolveField<Type, NoArguments, Context, EventLoop, EventLoopFuture<Output?>>? = nil
        ) throws {
        var r: GraphQLFieldResolve? = nil

        if let resolve = resolve {
            r = { source, _, context, eventLoopGroup, info in
                guard let s = source as? Type else {
                    throw GraphQLError(message: "Expected source type \(Type.self) but got \(Swift.type(of: source))")
                }

                guard let c = context as? Context else {
                    throw GraphQLError(message: "Expected context type \(Context.self) but got \(Swift.type(of: context))")
                }

                guard let e = eventLoopGroup as? EventLoop else {
                    throw GraphQLError(message: "Expected eventloop type \(EventLoop.self) but got \(Swift.type(of: eventLoopGroup))")
                }

                return try resolve(s, NoArguments(), c, e, info).flatMap{ return e.next().newSucceededFuture(result: $0) }
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
        resolve: ResolveField<Type, NoArguments, Context, EventLoop, EventLoopFuture<O>>? = nil
        ) throws {
        var r: GraphQLFieldResolve? = nil

        if let resolve = resolve {
            r = { source, _, context, eventLoopGroup, info in
                guard let s = source as? Type else {
                    throw GraphQLError(message: "Expected source type \(Type.self) but got \(Swift.type(of: source))")
                }

                guard let c = context as? Context else {
                    throw GraphQLError(message: "Expected context type \(Context.self) but got \(Swift.type(of: context))")
                }

                guard let e = eventLoopGroup as? EventLoop else {
                    throw GraphQLError(message: "Expected eventloop type \(EventLoop.self) but got \(Swift.type(of: eventLoopGroup))")
                }

                return try resolve(s, NoArguments(), c, e, info).flatMap{ return e.next().newSucceededFuture(result: $0) }
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
        resolve: ResolveField<Type, NoArguments, Context, EventLoop, EventLoopFuture<[O]>>? = nil
        ) throws {
        var r: GraphQLFieldResolve? = nil

        if let resolve = resolve {
            r = { source, _, context, eventLoopGroup, info in
                guard let s = source as? Type else {
                    throw GraphQLError(message: "Expected source type \(Type.self) but got \(Swift.type(of: source))")
                }

                guard let c = context as? Context else {
                    throw GraphQLError(message: "Expected context type \(Context.self) but got \(Swift.type(of: context))")
                }

                guard let e = eventLoopGroup as? EventLoop else {
                    throw GraphQLError(message: "Expected eventloop type \(EventLoop.self) but got \(Swift.type(of: eventLoopGroup))")
                }

                return try resolve(s, NoArguments(), c, e, info).flatMap{ return e.next().newSucceededFuture(result: $0) }
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
        resolve: ResolveField<Type, NoArguments, Context, EventLoop, EventLoopFuture<O>>? = nil
        ) throws {
        var r: GraphQLFieldResolve? = nil

        if let resolve = resolve {
            r = { source, _, context, eventLoopGroup, info in
                guard let s = source as? Type else {
                    throw GraphQLError(message: "Expected source type \(Type.self) but got \(Swift.type(of: source))")
                }

                guard let c = context as? Context else {
                    throw GraphQLError(message: "Expected context type \(Context.self) but got \(Swift.type(of: context))")
                }

                guard let e = eventLoopGroup as? EventLoop else {
                    throw GraphQLError(message: "Expected eventloop type \(EventLoop.self) but got \(Swift.type(of: eventLoopGroup))")
                }

                return  try resolve(s, NoArguments(), c, e, info).flatMap{ return e.next().newSucceededFuture(result: $0) }
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
        resolve: ResolveField<Type, A, Context, EventLoop, EventLoopFuture<O?>>? = nil
        ) throws {
        let arguments = try schema.arguments(type: A.self, field: name)

        let field = GraphQLField(
            type: try schema.getOutputType(from: (O?).self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: arguments,
            resolve: resolve.map { resolve in
                return { source, args, context, eventLoopGroup, info in
                    guard let s = source as? Type else {
                        throw GraphQLError(message: "Expected source type \(Type.self) but got \(Swift.type(of: source))")
                    }

                    let a = try A(map: args)

                    guard let c = context as? Context else {
                        throw GraphQLError(message: "Expected context type \(Context.self) but got \(Swift.type(of: context))")
                    }

                    guard let e = eventLoopGroup as? EventLoop else {
                        throw GraphQLError(message: "Expected eventloop type \(EventLoop.self) but got \(Swift.type(of: eventLoopGroup))")
                    }

                    return try resolve(s, a, c, e, info).flatMap{ return e.next().newSucceededFuture(result: $0) }
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
        resolve: ResolveField<Type, A, Context, EventLoop, EventLoopFuture<O>>? = nil
        ) throws {
        let arguments = try schema.arguments(type: A.self, field: name)

        let field = GraphQLField(
            type: try schema.getOutputType(from: O.self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: arguments,
            resolve: resolve.map { resolve in
                return { source, args, context, eventLoopGroup, info in
                    guard let s = source as? Type else {
                        throw GraphQLError(message: "Expected type \(Type.self) but got \(Swift.type(of: source))")
                    }

                    let a = try A(map: args)

                    guard let c = context as? Context else {
                        throw GraphQLError(message: "Expected context type \(Context.self) but got \(Swift.type(of: context))")
                    }

                    guard let e = eventLoopGroup as? EventLoop else {
                        throw GraphQLError(message: "Expected eventloop type \(EventLoop.self) but got \(Swift.type(of: eventLoopGroup))")
                    }

                    return try resolve(s, a, c, e, info).flatMap{ return e.next().newSucceededFuture(result: $0) }
                }
            }
        )

        fields[name] = field
    }
}
