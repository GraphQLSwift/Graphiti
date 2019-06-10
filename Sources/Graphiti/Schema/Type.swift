import GraphQL

public class ObjectTypeComponent<ObjectType, FieldKey : RawRepresentable, Context> where FieldKey.RawValue == String {
    
    let isTypeOf: GraphQLIsTypeOf = { source, _, _ in
        return source is ObjectType
    }
    
    func field(provider: TypeProvider) throws -> (String, GraphQLField) {
        fatalError()
    }
    
    func fields(provider: TypeProvider) throws -> GraphQLFieldMap {
        fatalError()
    }
}

private class MergerObjectTypeComponent<ObjectType, FieldKey : RawRepresentable, Context> : ObjectTypeComponent<ObjectType, FieldKey, Context> where FieldKey.RawValue == String {
    let components: [ObjectTypeComponent<ObjectType, FieldKey, Context>]
    
    init(components: [ObjectTypeComponent<ObjectType, FieldKey, Context>]) {
        self.components = components
    }
    
    override func fields(provider: TypeProvider) throws -> GraphQLFieldMap {
        var map: GraphQLFieldMap = [:]
        
        for component in self.components {
            let (name, field) = try component.field(provider: provider)
            map[name] = field
        }
        
        return map
    }
}

@_functionBuilder
public struct ObjectTypeBuilder<ObjectType, FieldKey : RawRepresentable, Context> where FieldKey.RawValue == String {
    public static func buildBlock(_ components: ObjectTypeComponent<ObjectType, FieldKey, Context>...) -> ObjectTypeComponent<ObjectType, FieldKey, Context> {
        return MergerObjectTypeComponent(components: components)
    }
}

public final class Type<RootType : FieldKeyProvider, Context, ObjectType : Encodable & FieldKeyProvider> : SchemaComponent<RootType, Context> {
    let name: String?
    let interfaces: [Any.Type]
    let component: ObjectTypeComponent<ObjectType, ObjectType.FieldKey, Context>
    
    override func update(schema: SchemaThingy) {
        let objectType = try! GraphQLObjectType(
            name: self.name ?? fixName(String(describing: ObjectType.self)),
            description: self.description,
            fields: self.component.fields(provider: schema),
            interfaces: self.interfaces.map {
                try! schema.getInterfaceType(from: $0)
            },
            isTypeOf: self.component.isTypeOf
        )
        
        try! schema.map(ObjectType.self, to: objectType)
    }
    
    public init(
        _ type: ObjectType.Type,
        name: String? = nil,
        interfaces: Any.Type...,
        @ObjectTypeBuilder<ObjectType, ObjectType.FieldKey, Context> component: () -> ObjectTypeComponent<ObjectType, ObjectType.FieldKey, Context>
    ) {
        self.name = name
        self.interfaces = interfaces
        self.component = component()
    }
}
