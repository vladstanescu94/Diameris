import Foundation
import SwiftData
import Domain

/// Disambiguates `Domain.Category` from the Objective-C `Category` type.
public typealias ExpenseCategory = Domain.Category

/// A user-created category. The built-in `Category.defaults` are never persisted.
@Model
public final class CustomCategory {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var sortOrder: Int
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        sortOrder: Int = 100
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    // MARK: - Conversion

    public func toCategory() -> ExpenseCategory {
        ExpenseCategory.custom(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            sortOrder: sortOrder
        )
    }

    public convenience init(from category: ExpenseCategory) {
        self.init(
            name: category.name,
            icon: category.icon,
            colorHex: category.colorHex,
            sortOrder: category.sortOrder
        )
    }
}
