import XCTest
import SwiftRewriterLib

class SwiftRewriter_ThreadingTests: XCTestCase {
    private var state = State()
    
    override func setUp() {
        super.setUp()
        
        state = State()
    }
    
    /// Tests multi-threading with a large number of input files
    func testMultithreadingStability() {
        var builder = MultiFileTestBuilder(test: self)
        
        for _ in 0..<16 {
            builder = produceNextClassFiles(classCount: 10, in: builder)
        }
        
        builder.transpile().assertExpectedSwiftFiles()
    }
}

private extension SwiftRewriter_ThreadingTests {
    func produceNextClassFiles(classCount: Int, in builder: MultiFileTestBuilder) -> MultiFileTestBuilder {
        var header = ""
        var implementation = ""
        var expectedSwift = ""
        
        for _ in 0..<classCount {
            let className = "Class\(state.nextClassId())"
            
            // Note: Extra line feeds at the end of each string are required to
            // make sure we don't produce code that is accidentally joined.
            
            header += """
            @interface \(className) : UIView
            @property (weak) \(className)* next;
            @property BOOL a;
            @property BOOL b;
            @property CGFloat c;
            - (void)myMethod;
            @end
            
            """
            
            implementation += """
            @implementation \(className)
            - (void)myMethod {
                for(int i = 0; i < (int)[self myOtherMethod]; i += 1) {
                    self.a;
                    self.b;
                }
                self.window.bounds;
            }
            - (CGFloat)myOtherMethod {
                return (10 + next.c) / 2;
            }
            @end
            
            """
            
            expectedSwift += """
            @objc
            class \(className): UIView {
                @objc weak var next: \(className)?
                @objc var a: Bool = false
                @objc var b: Bool = false
                @objc var c: CGFloat = 0.0
                \
            
                @objc
                func myMethod() {
                    var i: CInt = 0
                    while i < CInt(self.myOtherMethod()) {
                        defer {
                            i += 1
                        }
                        self.a
                        self.b
                    }
                    self.window?.bounds
                }
                @objc
                func myOtherMethod() -> CGFloat {
                    return (10 + (next?.c ?? 0.0)) / 2
                }
            }
            
            """
        }
        
        let fileName = "File\(state.nextFileId())"
        
        expectedSwift += "// End of file \(fileName).swift"
        
        return builder
            .file(name: fileName + ".h", header)
            .file(name: fileName + ".m", implementation)
            .expectSwiftFile(name: fileName + ".swift", expectedSwift)
    }
    
    struct State {
        var fileCounter: Int = 0
        var classCounter: Int = 0
        
        mutating func nextFileId() -> Int {
            defer {
                fileCounter += 1
            }
            
            return fileCounter
        }
        
        mutating func nextClassId() -> Int {
            defer {
                classCounter += 1
            }
            
            return classCounter
        }
    }
}
