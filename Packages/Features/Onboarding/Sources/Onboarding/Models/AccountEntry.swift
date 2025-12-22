import Foundation

/// Temporary account entry used during onboarding flow
/// Not persisted - converted to Account model on completion
public struct AccountEntry: Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var purpose: String?

    public init(name: String, purpose: String? = nil) {
        self.id = UUID()
        self.name = name
        self.purpose = purpose
    }
}
