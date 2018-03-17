import GrammarModels
import Foundation
import Utils
import SwiftRewriterLib

public struct DefaultIntentionPasses: IntentionPassSource {
    public var intentionPasses: [IntentionPass] = [
        FileTypeMergingIntentionPass(),
        ProtocolNullabilityPropagationToConformersIntentionPass(),
        PropertyMergeIntentionPass(),
        StoredPropertyToNominalTypesIntentionPass(),
        SwiftifyMethodSignaturesIntentionPass(),
        ImportDirectiveIntentionPass(),
        DetectNonnullReturnsIntentionPass()
    ]
    
    public init() {
        
    }
}
