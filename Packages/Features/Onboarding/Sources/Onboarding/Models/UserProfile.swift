import Foundation
import SwiftData

@Model
public final class UserProfile {
    public var name: String
    public var currencyCode: String
    public var createdAt: Date

    public init(name: String, currencyCode: String) {
        self.name = name
        self.currencyCode = currencyCode
        self.createdAt = Date()
    }
}
