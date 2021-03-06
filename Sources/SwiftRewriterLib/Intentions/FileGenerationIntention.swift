import GrammarModels
import SwiftAST

/// An intention to create a .swift file
public class FileGenerationIntention: Intention {
    /// Used to sort file generation intentions after multi-threaded parsing is
    /// finished.
    var _index: Int = 0
    
    /// The source path for this file
    public var sourcePath: String
    
    /// The intended output file path
    public var targetPath: String
    
    /// Gets the types to create on this file.
    public private(set) var typeIntentions: [TypeGenerationIntention] = []
    
    /// All preprocessor directives found on this file.
    public var preprocessorDirectives: [String] = []
    
    /// Gets the (Swift) import directives should be printed at this file's top
    /// header section.
    public var importDirectives: [String] = []
    
    /// Gets the intention collection that contains this file generation intention
    public internal(set) var intentionCollection: IntentionCollection?
    
    /// Returns `true` if there are no intentions and no preprocessor directives
    /// registered for this file.
    public var isEmpty: Bool {
        return isEmptyExceptDirectives && preprocessorDirectives.isEmpty
    }
    
    /// Returns `true` if there are no intentions registered for this file, not
    /// counting any recorded preprocessor directive.
    public var isEmptyExceptDirectives: Bool {
        return
            typeIntentions.isEmpty &&
                typealiasIntentions.isEmpty &&
                globalFunctionIntentions.isEmpty &&
                globalVariableIntentions.isEmpty
    }
    
    /// Gets the class extensions (but not main class declarations) to create
    /// on this file.
    public var extensionIntentions: [ClassExtensionGenerationIntention] {
        return typeIntentions.compactMap { $0 as? ClassExtensionGenerationIntention }
    }
    
    /// Gets the classes (but not class extensions) to create on this file.
    public var classIntentions: [ClassGenerationIntention] {
        return typeIntentions.compactMap { $0 as? ClassGenerationIntention }
    }
    
    /// Gets the classes and class extensions to create on this file.
    public var classTypeIntentions: [BaseClassIntention] {
        return typeIntentions.compactMap { $0 as? BaseClassIntention }
    }
    
    /// Gets the protocols to create on this file.
    public var protocolIntentions: [ProtocolGenerationIntention] {
        return typeIntentions.compactMap { $0 as? ProtocolGenerationIntention }
    }
    
    /// Gets the enums to create on this file.
    public var enumIntentions: [EnumGenerationIntention] {
        return typeIntentions.compactMap { $0 as? EnumGenerationIntention }
    }
    
    /// Gets the structs to create on this file.
    public var structIntentions: [StructGenerationIntention] {
        return typeIntentions.compactMap { $0 as? StructGenerationIntention }
    }
    
    /// Gets the typealias intentions to create on this file.
    public private(set) var typealiasIntentions: [TypealiasIntention] = []
    
    /// Gets the global functions to create on this file.
    public private(set) var globalFunctionIntentions: [GlobalFunctionGenerationIntention] = []
    
    /// Gets the global variables to create on this file.
    public private(set) var globalVariableIntentions: [GlobalVariableGenerationIntention] = []
    
    public let history: IntentionHistory = IntentionHistoryTracker()
    
    public var source: ASTNode?
    
    weak public var parent: Intention?
    
    public init(sourcePath: String, targetPath: String) {
        self.sourcePath = sourcePath
        self.targetPath = targetPath
        
        self.history.recordCreation(description: "Created from file \(sourcePath) to file \(targetPath)")
    }
    
    public func addType(_ intention: TypeGenerationIntention) {
        typeIntentions.append(intention)
        intention.parent = self
    }
    
    public func addTypealias(_ intention: TypealiasIntention) {
        typealiasIntentions.append(intention)
        intention.parent = self
    }
    
    public func removeTypes(where predicate: (TypeGenerationIntention) -> Bool) {
        for (i, intent) in typeIntentions.enumerated().reversed() {
            if predicate(intent) {
                intent.parent = nil
                typeIntentions.remove(at: i)
            }
        }
    }
    
    public func removeFunctions(where predicate: (GlobalFunctionGenerationIntention) -> Bool) {
        for (i, intent) in globalFunctionIntentions.enumerated().reversed() {
            if predicate(intent) {
                intent.parent = nil
                globalFunctionIntentions.remove(at: i)
            }
        }
    }
    
    public func removeClassTypes(where predicate: (BaseClassIntention) -> Bool) {
        for (i, intent) in typeIntentions.enumerated().reversed() {
            if let classType = intent as? BaseClassIntention, predicate(classType) {
                intent.parent = nil
                typeIntentions.remove(at: i)
            }
        }
    }
    
    public func removeGlobalVariables(where predicate: (GlobalVariableGenerationIntention) -> Bool) {
        for (i, intent) in globalVariableIntentions.enumerated().reversed() {
            if predicate(intent) {
                intent.parent = nil
                globalVariableIntentions.remove(at: i)
            }
        }
    }
    
    public func removeGlobalFunctions(where predicate: (GlobalFunctionGenerationIntention) -> Bool) {
        for (i, intent) in globalFunctionIntentions.enumerated().reversed() {
            if predicate(intent) {
                intent.parent = nil
                globalFunctionIntentions.remove(at: i)
            }
        }
    }
    
    public func removeTypealiases(where predicate: (TypealiasIntention) -> Bool) {
        for (i, intent) in typealiasIntentions.enumerated().reversed() {
            if predicate(intent) {
                intent.parent = nil
                typealiasIntentions.remove(at: i)
            }
        }
    }
    
    public func addProtocol(_ intention: ProtocolGenerationIntention) {
        typeIntentions.append(intention)
        intention.parent = self
    }
    
    public func addGlobalFunction(_ intention: GlobalFunctionGenerationIntention) {
        globalFunctionIntentions.append(intention)
        intention.parent = self
    }
    
    public func addGlobalVariable(_ intention: GlobalVariableGenerationIntention) {
        globalVariableIntentions.append(intention)
        intention.parent = self
    }
}
