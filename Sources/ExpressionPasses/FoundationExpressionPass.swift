import SwiftRewriterLib
import Utils
import SwiftAST

/// Applies passes to simplify known Foundation methods
public class FoundationExpressionPass: SyntaxNodeRewriterPass {
    
    public override func visitPostfix(_ exp: PostfixExpression) -> Expression {
        if let new = convertIsEqualToString(exp) {
            notifyChange()
            
            return super.visitExpression(new)
        }
        if let new = convertStringWithFormat(exp) {
            notifyChange()
            
            return super.visitExpression(new)
        }
        if let new = convertAddObjectsFromArray(exp) {
            notifyChange()
            
            return super.visitExpression(new)
        }
        if let new = convertClassCall(exp) {
            notifyChange()
            
            return super.visitExpression(new)
        }
        if let new = convertDataStructureInit(exp) {
            notifyChange()
            
            return super.visitExpression(new)
        }
        if let new = convertRespondsToSelector(exp) {
            notifyChange()
            
            return super.visitExpression(new)
        }
        
        return super.visitPostfix(exp)
    }
    
    /// Converts [<lhs> respondsToSelector:<selector>] -> <lhs>.responds(to: <selector>)
    func convertRespondsToSelector(_ exp: PostfixExpression) -> Expression? {
        guard let postfix = exp.exp.asPostfix, let fc = exp.functionCall else {
            return nil
        }
        guard postfix.member?.name == "respondsToSelector" else {
            return nil
        }
        guard fc.arguments.count == 1 else {
            return nil
        }
        
        postfix.op = .member("responds")
        exp.op = .functionCall(arguments: [
            FunctionArgument.labeled("to", fc.arguments[0].expression)
        ])
        
        exp.resolvedType = .bool
        
        return exp
    }
    
    /// Converts [<lhs> isEqualToString:<rhs>] -> <lhs> == <rhs>
    func convertIsEqualToString(_ exp: PostfixExpression) -> Expression? {
        guard let postfix = exp.exp.asPostfix,
            postfix.op == .member("isEqualToString"),
            let args = exp.functionCall?.arguments, args.count == 1 && !args.hasLabeledArguments() else {
                return nil
        }
        
        let res = postfix.exp.binary(op: .equals, rhs: args[0].expression)
        
        res.resolvedType = .bool
        
        return res
    }
    
    /// Converts [NSString stringWithFormat:@"format", <...>] -> String(format: "format", <...>)
    func convertStringWithFormat(_ exp: PostfixExpression) -> Expression? {
        guard exp.exp == .postfix(.identifier("NSString"), .member("stringWithFormat")),
            let args = exp.functionCall?.arguments, args.count > 0 else {
                return nil
        }
        
        let newArgs: [FunctionArgument] = [
            .labeled("format", args[0].expression),
            ] + args.dropFirst()
        
        exp.exp = .identifier("String")
        exp.op = .functionCall(arguments: newArgs)
        
        exp.resolvedType = .string
        
        return exp
    }
    
    /// Converts [<array> addObjectsFromArray:<exp>] -> <array>.addObjects(from: <exp>)
    func convertAddObjectsFromArray(_ exp: PostfixExpression) -> Expression? {
        guard let memberPostfix = exp.exp.asPostfix, memberPostfix.op == .member("addObjectsFromArray"),
            let args = exp.functionCall?.arguments, args.count == 1 else {
                return nil
        }
        
        let newArgs: [FunctionArgument] = [
            .labeled("from", args[0].expression),
            ]
        
        exp.exp = .postfix(memberPostfix.exp, .member("addObjects"))
        exp.op = .functionCall(arguments: newArgs)
        
        exp.resolvedType = .void
        
        return exp
    }
    
    /// Converts [Type class] and [expression class] expressions
    func convertClassCall(_ exp: PostfixExpression) -> Expression? {
        guard let args = exp.functionCall?.arguments, args.count == 0 else {
            return nil
        }
        guard let classMember = exp.exp.asPostfix, classMember.op == .member("class") else {
            return nil
        }
        
        // Use resolved expression type, if available
        if case .metatype? = classMember.exp.resolvedType {
            let exp = Expression.postfix(classMember.exp, .member("self"))
            exp.resolvedType = classMember.exp.resolvedType
            
            return exp
        } else if !classMember.exp.isErrorTyped && classMember.exp.resolvedType != nil {
            return Expression.postfix(.identifier("type"),
                                      .functionCall(arguments: [
                                        .labeled("of", classMember.exp)
                                        ]))
        }
        
        // Deduce using identifier or expression capitalization
        switch classMember.exp {
        case let ident as IdentifierExpression where ident.identifier.startsUppercased:
            return Expression.postfix(classMember.exp, .member("self"))
        default:
            return Expression.postfix(.identifier("type"),
                                      .functionCall(arguments: [
                                        .labeled("of", classMember.exp)
                                        ]))
        }
    }
    
    /// Converts [NSArray array], [NSDictionary dictionary], etc. constructs
    func convertDataStructureInit(_ exp: PostfixExpression) -> Expression? {
        guard let args = exp.functionCall?.arguments, args.count == 0 else {
            return nil
        }
        guard let initMember = exp.exp.asPostfix, let typeName = initMember.exp.asIdentifier?.identifier else {
            return nil
        }
        guard let initName = initMember.member?.name else {
            return nil
        }
        
        switch (typeName, initName) {
        case ("NSArray", "array"),
             ("NSMutableArray", "array"),
             ("NSDictionary", "dictionary"),
             ("NSMutableDictionary", "dictionary"),
             ("NSSet", "set"),
             ("NSMutableSet", "set"),
             ("NSDate", "date"):
            let res = Expression.identifier(typeName).call()
            res.resolvedType = .typeName(typeName)
            
            return res
        default:
            return nil
        }
    }
}
