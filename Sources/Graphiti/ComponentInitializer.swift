public final class ComponentInitializer<RootType : Keyable, Context> {
    let component: Component<RootType, Context>
    
    init(_ component: Component<RootType, Context>) {
        self.component = component
    }
    
    @discardableResult
    public func description(_ description: String) -> Self {
        component.description = description
        return self
    }
}
