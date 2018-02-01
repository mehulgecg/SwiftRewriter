import XCTest
@testable import ObjcParser
import GrammarModels

class ObjcParser_ClassPropertyParseTests: XCTestCase {
    
    func testParseSimpleProperty() throws {
        let source = """
            @interface MyClass
            @property BOOL myProperty1;
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestPropertyNode(source: source, parser: sut)
        
        let keywordsProp1 = result.childrenMatching(type: KeywordNode.self)
        XCTAssertTrue(keywordsProp1.contains { $0.keyword == .atProperty })
        XCTAssertEqual(result.type.type, .struct("BOOL"))
        XCTAssertEqual(result.identifier.name, "myProperty1")
        XCTAssert(result.childrenMatching(type: TokenNode.self).contains { $0.token.type == .semicolon })
        XCTAssert(sut.diagnostics.errors.count == 0, sut.diagnostics.errors.description)
    }
    
    func testParsePropertyWithGenericType() throws {
        // Arrange
        let source = """
            @interface MyClass
            @property NSArray<NSString*>* myProperty3;
            @end
            """
        let sut = ObjcParser(string: source)
        
        // Act
        let result = _parseTestPropertyNode(source: source, parser: sut)
        
        // Assert
        let keywordsProp1 = result.childrenMatching(type: KeywordNode.self)
        XCTAssertTrue(keywordsProp1.contains { $0.keyword == .atProperty })
        XCTAssertEqual(result.type.type, .pointer(.generic("NSArray", parameters: [.pointer(.struct("NSString"))])))
        XCTAssertEqual(result.identifier.name, "myProperty3")
        XCTAssert(result.childrenMatching(type: TokenNode.self).contains { $0.token.type == .semicolon })
        XCTAssert(sut.diagnostics.errors.count == 0, sut.diagnostics.errors.description)
    }
    
    func testParsePropertyWithModifiers() throws {
        let source = """
            @interface MyClass
            @property ( atomic, nonatomic , copy ) BOOL myProperty1;
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestPropertyNode(source: source, parser: sut)
        
        XCTAssertEqual(result.type.type, .struct("BOOL"))
        XCTAssertEqual(result.identifier.name, "myProperty1")
        XCTAssertNotNil(result.modifierList)
        XCTAssertEqual(result.modifierList?.keywordModifiers[0], "atomic")
        XCTAssertEqual(result.modifierList?.keywordModifiers[1], "nonatomic")
        XCTAssertEqual(result.modifierList?.keywordModifiers[2], "copy")
        XCTAssert(sut.diagnostics.errors.count == 0, sut.diagnostics.errors.description)
    }
    
    func testParsePropertyWithGetterModifier() throws {
        let source = """
            @interface MyClass
            @property (getter=isEnabled) BOOL enabled;
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestPropertyNode(source: source, parser: sut)
        
        XCTAssertEqual(result.type.type, .struct("BOOL"))
        XCTAssertEqual(result.identifier.name, "enabled")
        XCTAssertNotNil(result.modifierList)
        XCTAssertEqual(result.modifierList?.getterModifiers[0], "isEnabled")
        XCTAssert(sut.diagnostics.errors.count == 0, sut.diagnostics.errors.description)
    }
    
    func testParsePropertyWithSetterModifier() throws {
        let source = """
            @interface MyClass
            @property (setter=setIsEnabled:) BOOL enabled;
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestPropertyNode(source: source, parser: sut)
        
        XCTAssertEqual(result.type.type, .struct("BOOL"))
        XCTAssertEqual(result.identifier.name, "enabled")
        XCTAssertNotNil(result.modifierList)
        XCTAssertEqual(result.modifierList?.setterModifiers[0], "setIsEnabled")
        XCTAssert(sut.diagnostics.errors.count == 0, sut.diagnostics.errors.description)
    }
    
    func testParsePropertyWithModifiersRecovery() throws {
        let source = """
            @interface MyClass
            @property ( atomic, nonatomic , ) BOOL myProperty1;
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestPropertyNode(source: source, parser: sut)
        
        XCTAssertEqual(result.type.type, .struct("BOOL"))
        XCTAssertEqual(result.identifier.name, "myProperty1")
        XCTAssertNotNil(result.modifierList)
        XCTAssertEqual(result.modifierList?.keywordModifiers[0], "atomic")
        XCTAssertEqual(result.modifierList?.keywordModifiers[1], "nonatomic")
        XCTAssertEqual(sut.diagnostics.errors.count, 1)
    }
    
    func testParsePropertyMissingNameRecovery() throws {
        let source = """
            @interface MyClass
            @property BOOL ;
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestPropertyNode(source: source, parser: sut)
        
        XCTAssertEqual(result.type.type, .struct("BOOL"))
        XCTAssertFalse(result.identifier.exists)
        XCTAssertNil(result.modifierList)
        XCTAssertEqual(result.childrenMatching(type: TokenNode.self)[0].token.type, .semicolon)
        XCTAssertEqual(sut.diagnostics.errors.count, 1)
    }
    
    func testParsePropertyMissingTypeAndNameRecovery() throws {
        let source = """
            @interface MyClass
            @property ;
            @end
            """
        let sut = ObjcParser(string: source)
        
        let result = _parseTestPropertyNode(source: source, parser: sut)
        
        XCTAssertEqual(result.type.exists, false)
        XCTAssertFalse(result.identifier.exists)
        XCTAssertNil(result.modifierList)
        XCTAssertEqual(result.childrenMatching(type: TokenNode.self)[0].token.type, .semicolon)
        XCTAssertEqual(sut.diagnostics.errors.count, 2)
    }
    
    private func _parseTestPropertyNode(source: String, parser: ObjcParser, file: String = #file, line: Int = #line) -> PropertyDefinition {
        do {
            try parser.parse()
            
            let node =
                parser.rootNode
                    .firstChild(ofType: ObjcClassInterface.self)?
                    .firstChild(ofType: PropertyDefinition.self)
            return node!
        } catch {
            recordFailure(withDescription: "Failed to parse test '\(source)': \(error)", inFile: #file, atLine: line, expected: false)
            fatalError()
        }
    }
}
