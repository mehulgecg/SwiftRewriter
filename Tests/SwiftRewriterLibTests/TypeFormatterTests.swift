import XCTest
import SwiftRewriterLib
import SwiftAST

class TypeFormatterTests: XCTestCase {
    func testAsStringMethodFromType() {
        let type =
            KnownTypeBuilder(typeName: "A")
                .method(withSignature:
                    FunctionSignature(name: "a",
                                      parameters: [ParameterSignature(label: nil, name: "a", type: .int)],
                                      returnType: .void,
                                      isStatic: false)
                ).build()
        
        XCTAssertEqual(
            "A.a(_ a: Int)",
            TypeFormatter.asString(method: type.knownMethods[0], ofType: type)
        )
    }
    
    func testAsStringPropertyFromType() {
        let type =
            KnownTypeBuilder(typeName: "A")
                .property(named: "a", type: .int)
                .build()
        
        XCTAssertEqual(
            "A.a: Int",
            TypeFormatter.asString(property: type.knownProperties[0], ofType: type)
        )
    }
    
    func testAsStringPropertyFromTypeWithTypeNameAndVarKeywordAndAccessors() {
        let storage = ValueStorage(type: .int, ownership: .weak, isConstant: true)
        let type =
            KnownTypeBuilder(typeName: "A")
                .property(named: "a", storage: storage, isStatic: false, optional: false)
                .build()
        
        XCTAssertEqual(
            "weak var A.a: Int { get set }",
            TypeFormatter.asString(property: type.knownProperties[0], ofType: type,
                                   withTypeName: true, includeVarKeyword: true,
                                   includeAccessors: true)
        )
    }
    
    func testAsStringPropertyFromTypeWithArrayType() {
        let type =
            KnownTypeBuilder(typeName: "A")
                .property(named: "a", type: .array(.int))
                .build()
        
        XCTAssertEqual(
            "A.a: [Int]",
            TypeFormatter.asString(property: type.knownProperties[0], ofType: type)
        )
    }
    
    func testAsStringPropertyFromTypeWithOptionalArrayType() {
        let type =
            KnownTypeBuilder(typeName: "A")
                .property(named: "a", type: .optional(.array(.int)))
                .build()
        
        XCTAssertEqual(
            "A.a: [Int]?",
            TypeFormatter.asString(property: type.knownProperties[0], ofType: type)
        )
    }
    
    func testAsStringFieldFromType() {
        let type =
            KnownTypeBuilder(typeName: "A")
                .build()
        
        let field =
            InstanceVariableGenerationIntention(
                name: "a",
                storage: ValueStorage(type: .int,
                                      ownership: .strong,
                                      isConstant: false)
            )
        
        XCTAssertEqual(
            "A.a: Int",
            TypeFormatter.asString(field: field, ofType: type)
        )
    }
    
    func testAsStringExtension() {
        let extA = ClassExtensionGenerationIntention(typeName: "A")
        let extB = ClassExtensionGenerationIntention(typeName: "B")
        extB.categoryName = "Category"
        
        XCTAssertEqual("extension A", TypeFormatter.asString(extension: extA))
        XCTAssertEqual("extension B (Category)", TypeFormatter.asString(extension: extB))
    }
    
    func testAsStringFunctionSignature() {
        let sig1 = FunctionSignature(name: "abc", parameters: [],
                                     returnType: .int, isStatic: false)
        
        let sig2 = FunctionSignature(name: "abc",
                                     parameters: [ParameterSignature(label: "a", name: "b", type: .float)],
                                     returnType: .void,
                                     isStatic: false)
        
        let sig3 = FunctionSignature(name: "abc",
                                     parameters: [ParameterSignature(label: "a", name: "b", type: .float),
                                                  ParameterSignature(label: "c", name: "c", type: .int)],
                                     returnType: .void,
                                     isStatic: true)
        
        XCTAssertEqual("abc() -> Int", TypeFormatter.asString(signature: sig1, includeName: true))
        XCTAssertEqual("() -> Int", TypeFormatter.asString(signature: sig1, includeName: false))
        
        XCTAssertEqual("abc(a b: Float)", TypeFormatter.asString(signature: sig2, includeName: true))
        XCTAssertEqual("(a b: Float)", TypeFormatter.asString(signature: sig2, includeName: false))
        
        XCTAssertEqual("static abc(a b: Float, c: Int)", TypeFormatter.asString(signature: sig3, includeName: true))
        XCTAssertEqual("static (a b: Float, c: Int)", TypeFormatter.asString(signature: sig3, includeName: false))
        
        // Test default values for `includeName`
        XCTAssertEqual("() -> Int", TypeFormatter.asString(signature: sig1))
        XCTAssertEqual("(a b: Float)", TypeFormatter.asString(signature: sig2))
        XCTAssertEqual("static (a b: Float, c: Int)", TypeFormatter.asString(signature: sig3))
    }
    
    func testAsStringKnownType() {
        let type = KnownTypeBuilder(typeName: "A", kind: .struct)
            .constructor()
            .constructor(shortParameters: [("a", .int), ("b", .int)], annotations: ["Annotation"])
            .field(named: "readOnlyField", type: .string, isConstant: true, annotations: ["Annotation"])
            .field(named: "field", type: .string)
            .property(named: "prop", type: .optional(.nsArray), annotations: ["Annotation"])
            .property(named: "readOnlyProp", type: "A", accessor: .getter, annotations: ["Annotation"])
            .protocolConformance(protocolName: "Protocol")
            .method(withSignature: FunctionSignature(
                name: "methodA",
                parameters: [
                    ParameterSignature(label: nil, name: "c", type: .int)
                ],
                returnType: .string),
                    annotations: ["Annotation"]
            )
            .build()
        
        let result = TypeFormatter.asString(knownType: type)
        let expected = """
            struct A: Protocol {
                // Annotation
                let readOnlyField: String
                var field: String
                
                // Annotation
                var prop: NSArray?
                
                // Annotation
                var readOnlyProp: A { get }
                
                init()
                
                // Annotation
                init(a: Int, b: Int)
                
                // Annotation
                func methodA(_ c: Int) -> String
            }
            """
        
        XCTAssertEqual(result, expected, "\n" + result.makeDifferenceMarkString(against: expected))
    }
    
    func testAsStringKnownTypeEnum() {
        let type = KnownTypeBuilder(typeName: "A", kind: .enum)
            .enumRawValue(type: .int)
            .enumCase(named: "a")
            .enumCase(named: "b", rawValue: .constant(1))
            .build()
        
        let result = TypeFormatter.asString(knownType: type)
        let expected = """
            enum A: Int {
                case a
                case b
            }
            """
        
        XCTAssertEqual(result, expected, "\n" + result.makeDifferenceMarkString(against: expected))
    }
    
    func testAsStringEmptyInitializer() {
        let initializer = InitGenerationIntention(parameters: [])
        
        let result = TypeFormatter.asString(initializer: initializer)
        let expected = """
            init()
            """
        
        XCTAssertEqual(result, expected, "\n" + result.makeDifferenceMarkString(against: expected))
    }
    
    func testAsStringFailableInitializer() {
        let initializer = InitGenerationIntention(parameters: [])
        initializer.isFailable = true
        
        let result = TypeFormatter.asString(initializer: initializer)
        let expected = """
            init?()
            """
        
        XCTAssertEqual(result, expected, "\n" + result.makeDifferenceMarkString(against: expected))
    }
    
    func testAsStringConvenienceInitializer() {
        let initializer = InitGenerationIntention(parameters: [])
        initializer.isConvenience = true
        
        let result = TypeFormatter.asString(initializer: initializer)
        let expected = """
            convenience init()
            """
        
        XCTAssertEqual(result, expected, "\n" + result.makeDifferenceMarkString(against: expected))
    }
    
    func testAsStringParameteredInitializer() {
        let initializer =
            InitGenerationIntention(
                parameters: [
                    ParameterSignature(label: "label", name: "name", type: .int)
                ])
        
        let result = TypeFormatter.asString(initializer: initializer)
        let expected = """
            init(label name: Int)
            """
        
        XCTAssertEqual(result, expected, "\n" + result.makeDifferenceMarkString(against: expected))
    }
}
