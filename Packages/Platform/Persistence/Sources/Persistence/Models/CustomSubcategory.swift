import Foundation
import SwiftData
import Domain

/// SwiftData entity for user-created custom subcategories
/// Default subcategories from Domain.Subcategory.defaults are NOT persisted.
@Model
public final class CustomSubcategory {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var categoryId: UUID
    public var sortOrder: Int
    public var createdAt: Date

    public init(
        name: String,
        categoryId: UUID,
        sortOrder: Int = 100
    ) {
        self.id = UUID()
        self.name = name
        self.categoryId = categoryId
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    // MARK: - Conversion

    /// Convert to Domain Subcategory
    public func toSubcategory() -> Subcategory {
        Subcategory.custom(
            id: id,
            name: name,
            categoryId: categoryId,
            sortOrder: sortOrder
        )
    }

    /// Create from Domain Subcategory (for custom subcategories only)
    public convenience init(from subcategory: Subcategory) {
        self.init(
            name: subcategory.name,
            categoryId: subcategory.categoryId,
            sortOrder: subcategory.sortOrder
        )
    }
}
