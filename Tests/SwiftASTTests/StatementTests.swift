import XCTest
import SwiftAST

class StatementTests: XCTestCase {
    func testCreatingCompoundStatementWithLiteralProperlySetsParents() {
        let brk = BreakStatement()
        let stmt: CompoundStatement = [
            brk
        ]
        
        XCTAssert(brk.parent === stmt)
    }
}
