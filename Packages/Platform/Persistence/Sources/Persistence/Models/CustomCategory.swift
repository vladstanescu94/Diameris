import Foundation
import SwiftData
import Domain

/// Type alias to disambiguate from objc_category
public typealias ExpenseCategory = Domain.Category

/// SwiftData entity for user-created custom categories
/// Default categories from Domain.Category.defaults are NOT persisted.
@Model
public final class CustomCategory {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var sortOrder: Int
    public var createdAt: Date

    public init(
        name: String,
        icon: String,
        colorHex: String,
        sortOrder: Int = 100
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    // MARK: - Conversion

    /// Convert to Domain Category
    public func toCategory() -> ExpenseCategory {
        ExpenseCategory.custom(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            sortOrder: sortOrder
        )
    }

    /// Create from Domain Category (for custom categories only)
    public convenience init(from category: ExpenseCategory) {
        self.init(
            name: category.name,
            icon: category.icon,
            colorHex: category.colorHex,
            sortOrder: category.sortOrder
        )
    }
}
