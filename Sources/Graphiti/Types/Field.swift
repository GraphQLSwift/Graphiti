import GraphQL

public protocol InputType : MapInitializable {}
public protocol OutputType : MapFallibleRepresentable {}

public typealias DefaultValue = MapRepresentable

public protocol ArgumentInfo {
    static var defaultValue: DefaultValue? { get }
    static var description: String? { get }
}

public protocol Arguments : MapInitializable {}

public protocol Argument : MapInitializable, ArgumentInfo {}

extension Optional : Argument {
    // TODO: maybe make this a throwable function and throw if wrapped does not conform to Argument
    public static var defaultValue: DefaultValue? {
        guard let wrapped = Wrapped.self as? Argument.Type else {
            return nil
        }

        return wrapped.defaultValue
    }

    public static var description: String? {
        guard let wrapped = Wrapped.self as? Argument.Type else {
            return nil
        }

        return wrapped.description
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
        var args: [String: GraphQLArgument] = [:]
        var addValueField: [String: Void]  = [:]

        for argument in try properties(A.self) {
            switch argument.type {
            case let argumentInfo as ArgumentInfo.Type:
                var type: GraphQLInputType! = nil
                var info = argumentInfo

                // TODO: check if wrapped type is ArgumentInfo and throw
                if let wrapper = argumentInfo as? Wrapper.Type {
                    info = wrapper.wrappedType as! ArgumentInfo.Type
                }

                for property in try properties(info) {
                    if property.key == "value" {
                        type = try getInputType(from: property.type, field: name)
                    }
                }


                if type == nil {
                    throw GraphQLError(
                        message:
                        "Cannot use type \"\(argument.type)\" as an argument. " +
                            "\"\(argument.type)\" needs a property named \"value\" " +
                        "with a type that adopts the \"ArgumentType\" protocol."
                    )
                }

                let arg = GraphQLArgument(
                    type: type,
                    description: argumentInfo.description,
                    defaultValue: argumentInfo.defaultValue?.map
                )

                args[argument.key] = arg
                addValueField[argument.key] = ()
            case let argumentType as InputType.Type:
                let arg = GraphQLArgument(
                    type: try getInputType(from: argumentType, field: name)
                )

                args[argument.key] = arg
            default:
                throw GraphQLError(
                    message:
                    "Cannot use type \"\(argument.type)\" as an argument. " +
                    "\"\(argument.type)\" does not conform to the \"Argument\" protocol."
                )
            }
        }

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

                    for (key, value) in dict {
                        if addValueField[key] != nil {
                            dict[key] = ["value": value]
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
        var args: [String: GraphQLArgument] = [:]
        var addValueField: [String: Void]  = [:]

        for argument in try properties(A.self) {
            switch argument.type {
            case let argumentInfo as ArgumentInfo.Type:
                var type: GraphQLInputType! = nil
                var info = argumentInfo

                // TODO: check if wrapped type is ArgumentInfo and throw
                if let wrapper = argumentInfo as? Wrapper.Type {
                    info = wrapper.wrappedType as! ArgumentInfo.Type
                }

                for property in try properties(info) {
                    if property.key == "value" {
                        type = try getInputType(from: property.type, field: name)
                    }
                }


                if type == nil {
                    throw GraphQLError(
                        message:
                        "Cannot use type \"\(argument.type)\" as an argument. " +
                            "\"\(argument.type)\" needs a property named \"value\" " +
                        "with a type that adopts the \"ArgumentType\" protocol."
                    )
                }

                let arg = GraphQLArgument(
                    type: type,
                    description: argumentInfo.description,
                    defaultValue: argumentInfo.defaultValue?.map
                )

                args[argument.key] = arg
                addValueField[argument.key] = ()
            case let argumentType as InputType.Type:
                let arg = GraphQLArgument(
                    type: try getInputType(from: argumentType, field: name)
                )

                args[argument.key] = arg
            default:
                throw GraphQLError(
                    message:
                    "Cannot use type \"\(argument.type)\" as an argument. " +
                    "\"\(argument.type)\" does not conform to the \"Argument\" protocol."
                )
            }
        }

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
                    
                    for (key, value) in dict {
                        if addValueField[key] != nil {
                            dict[key] = ["value": value]
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
