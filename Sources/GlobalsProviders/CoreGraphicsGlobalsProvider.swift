import SwiftAST
import SwiftRewriterLib
import Commons

public class CoreGraphicsGlobalsProvider: GlobalsProvider {
    private static var provider = InnerCoreGraphicsGlobalsProvider()
    
    public init() {
        
    }
    
    public func knownTypeProvider() -> KnownTypeProvider {
        return CollectionKnownTypeProvider(knownTypes: CoreGraphicsGlobalsProvider.provider.types)
    }
    
    public func typealiasProvider() -> TypealiasProvider {
        return CollectionTypealiasProvider(aliases: CoreGraphicsGlobalsProvider.provider.typealiases)
    }
    
    public func definitionsSource() -> DefinitionsSource {
        return CoreGraphicsGlobalsProvider.provider.definitions
    }
}

private class InnerCoreGraphicsGlobalsProvider: BaseGlobalsProvider {
    
    var definitions: ArrayDefinitionsSource = ArrayDefinitionsSource(definitions: [])
    
    public override init() {
        
    }
    
    override func createTypes() {
        createCGPoint()
        createCGSize()
        createCGRect()
    }
    
    override func createDefinitions() {
        super.createDefinitions()
        
        definitions = ArrayDefinitionsSource(definitions: globals)
    }
    
    func createCGPoint() {
        makeType(named: "CGPoint", kind: .struct) { (type) -> (KnownType) in
            type
                // Statics
                .property(named: "zero", type: .typeName("CGPoint"), isStatic: true,
                          accessor: .getter)
                // Fields
                .field(named: "x", type: .cgFloat)
                .field(named: "y", type: .cgFloat)
                .constructor()
                .constructor(shortParameters: [
                    ("x", type: .cgFloat), ("y", type: .cgFloat)
                ])
                .build()
        }
    }
    
    func createCGSize() {
        makeType(named: "CGSize", kind: .struct) { (type) -> (KnownType) in
            type
                // Statics
                .property(named: "zero", type: .typeName("CGSize"), isStatic: true,
                          accessor: .getter)
                // Fields
                .field(named: "width", type: .cgFloat)
                .field(named: "height", type: .cgFloat)
                .constructor()
                .constructor(shortParameters: [
                    ("width", type: .cgFloat), ("height", type: .cgFloat)
                ])
                .build()
        }
    }
    
    func createCGRect() {
        makeType(named: "CGRect", kind: .struct) { type in
            type
                // Statics
                .field(named: "null", type: .typeName("CGRect"), isConstant: true,
                       isStatic: true)
                .field(named: "infinite", type: .typeName("CGRect"), isConstant: true,
                       isStatic: true)
                .property(named: "zero", type: .typeName("CGRect"), isStatic: true,
                          accessor: .getter)
                // Fields
                .field(named: "origin", type: .typeName("CGPoint"))
                .field(named: "size", type: .typeName("CGSize"))
                // Properties
                .property(named: "minX", type: .cgFloat, accessor: .getter)
                .property(named: "midX", type: .cgFloat, accessor: .getter)
                .property(named: "maxX", type: .cgFloat, accessor: .getter)
                .property(named: "minY", type: .cgFloat, accessor: .getter)
                .property(named: "midY", type: .cgFloat, accessor: .getter)
                .property(named: "maxY", type: .cgFloat, accessor: .getter)
                .property(named: "maxY", type: .cgFloat, accessor: .getter)
                .property(named: "width", type: .cgFloat, accessor: .getter)
                .property(named: "height", type: .cgFloat, accessor: .getter)
                .property(named: "standardized", type: .typeName("CGRect"), accessor: .getter)
                .property(named: "isEmpty", type: .bool, accessor: .getter)
                .property(named: "isNull", type: .bool, accessor: .getter)
                .property(named: "isInfinite", type: .bool, accessor: .getter)
                .property(named: "integral", type: .typeName("CGRect"), accessor: .getter)
                // Constructors
                .constructor()
                .constructor(shortParameters: [
                    ("x", type: .cgFloat), ("y", type: .cgFloat),
                    ("width", type: .cgFloat), ("height", type: .cgFloat)
                ])
                .method(named: "insetBy", shortParams: [("dx", .cgFloat), ("dy", .cgFloat)],
                        returning: .typeName("CGRect"))
                .method(named: "offsetBy", shortParams: [("dx", .cgFloat), ("dy", .cgFloat)],
                        returning: .typeName("CGRect"))
                .build()
        }
    }
}
