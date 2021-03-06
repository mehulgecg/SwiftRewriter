/// Defines the ownership of a variable storage
public enum Ownership: String, Equatable, Codable {
    case strong
    case weak
    case unownedSafe = "unowned(safe)"
    case unownedUnsafe = "unowned(unsafe)"
}
