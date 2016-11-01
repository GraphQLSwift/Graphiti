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

func getArgument(argumentType: MapInitializable.Type, field: String) throws -> GraphQLArgument {
    return GraphQLArgument(
        type: try getInputType(from: argumentType, field: field)
    )
}

func getArgument(
    propertyType: Any.Type,
    argumentInfo: ArgumentInfo.Type,
    field: String
) throws -> GraphQLArgument {
    var inputType: GraphQLInputType? = nil

    // TODO: Change to Reflection.get
    for property in try properties(argumentInfo) {
        if property.key == "value" {
            inputType = try getInputType(from: property.type, field: field)
            break
        }
    }

    guard let type = inputType else {
        throw GraphQLError(
            message:
            "Cannot use type \"\(propertyType)\" as an argument. " +
                "\"\(propertyType)\" needs a property named \"value\" " +
            "with a type that adopts the \"ArgumentType\" protocol."
        )
    }

    return GraphQLArgument(
        type: type,
        description: argumentInfo.description,
        defaultValue: argumentInfo.defaultValue?.map
    )
}

func getArgument(
    propertyType: Any.Type,
    field: String
) throws -> (GraphQLArgument, Bool) {
    switch propertyType {
    case let argumentInfo as ArgumentInfo.Type:
        let argument = try getArgument(
            propertyType: propertyType,
            argumentInfo: argumentInfo,
            field: field
        )

        return (argument, true)
    case let argumentType as MapInitializable.Type:
        let argument = try getArgument(
            argumentType: argumentType,
            field: field
        )

        return (argument, false)
    default:
        throw GraphQLError(
            message:
            "Cannot use type \"\(propertyType)\" as an argument. " +
            "\"\(propertyType)\" does not conform to the \"Argument\" protocol."
        )
    }
}

func arguments(
    type: Any.Type,
    field: String
) throws -> ([String: GraphQLArgument], [String: Void])  {
    var arguments: [String: GraphQLArgument] = [:]
    var argumentInfoMap: [String: Void]  = [:]

    for property in try properties(type) {
        let (argument, hasArgumentInfo) = try getArgument(
            propertyType: property.type,
            field: field
        )

        arguments[property.key] = argument

        if hasArgumentInfo {
            argumentInfoMap[property.key] = Void()
        }
    }

    return (arguments, argumentInfoMap)
}

public class FieldBuilder<Type> {
    var fields: GraphQLFieldMap = [:]

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
            type: try getOutputType(from: (TypeReference<O>?).self, field: name),
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
            type: try getOutputType(from: TypeReference<O>.self, field: name),
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
            type: try getOutputType(from: [TypeReference<O>].self, field: name),
            description: description,
            deprecationReason: deprecationReason,
            args: [:],
            resolve: r
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
            type: try getOutputType(from: O.self, field: name),
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
        let (args, argumentInfoMap) = try arguments(
            type: A.self,
            field: name
        )

        let field = GraphQLField(
            type: try getOutputType(from: (O?).self, field: name),
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
        let (args, argumentInfoMap) = try arguments(
            type: A.self,
            field: name
        )

        let field = GraphQLField(
            type: try getOutputType(from: O.self, field: name),
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
