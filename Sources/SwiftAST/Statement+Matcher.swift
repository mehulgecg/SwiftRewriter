public protocol Matchable {
    
}

public protocol ValueMatcherConvertible {
    associatedtype Target
    
    func asMatcher() -> ValueMatcher<Target>
}

extension ValueMatcher: ValueMatcherConvertible {
    public func asMatcher() -> ValueMatcher<T> {
        return self
    }
}

extension ValueMatcherConvertible where Target == Self, Self: Equatable {
    public func asMatcher() -> ValueMatcher<Self> {
        return ValueMatcher<Self>().match { $0 == self }
    }
}

public extension Matchable {
    
    public static func matcher() -> ValueMatcher<Self> {
        return ValueMatcher()
    }
    
    public func matches(_ matcher: ValueMatcher<Self>) -> Bool {
        return matcher.matches(self)
    }
    
}

public extension Statement {
    
    public static func matcher<T: Statement>(_ matcher: SyntaxMatcher<T>) -> SyntaxMatcher<T> {
        return matcher
    }
    
}

public extension ValueMatcher where T: Statement {
    
    public func anyStatement() -> ValueMatcher<Statement> {
        return ValueMatcher<Statement>().match { (value) -> Bool in
            if let value = value as? T {
                return self.matches(value)
            }
            
            return false
        }
    }
    
}

public func hasElse() -> SyntaxMatcher<IfStatement> {
    return SyntaxMatcher().keyPath(\.elseBody, !isNil())
}

extension Statement: Matchable {
    
}
