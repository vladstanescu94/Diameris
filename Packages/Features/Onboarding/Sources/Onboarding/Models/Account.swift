import Foundation
import SwiftData

@Model
public final class Account {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var purpose: String?
    public var isPrimary: Bool
    public var sortOrder: Int

    public init(name: String, purpose: String? = nil, isPrimary: Bool = false, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.purpose = purpose
        self.isPrimary = isPrimary
        self.sortOrder = sortOrder
    }
}
