import Foundation
import Testing
@testable import Domain

struct CategoryTests {

    /// Expenses persist `categoryId`; changing one of these orphans every stored expense in it.
    @Test(arguments: zip(
        Category.defaults,
        (1...8).map { "D1A0000\($0)-0000-0000-0000-00000000000\($0)" }
    ))
    func `Default category ids are stable`(category: Domain.Category, persistedId: String) {
        #expect(category.id.uuidString == persistedId)
        #expect(Category.defaultCategory(for: category.id) == category)
    }

    @Test func `Defaults are unique and ordered`() {
        #expect(Set(Category.defaults.map(\.id)).count == Category.defaults.count)
        #expect(Category.defaults.map(\.sortOrder) == Array(Category.defaults.indices))
        #expect(Category.defaults.allSatisfy { $0.isDefault })
    }

    @Test func `Custom categories sort after defaults and are not default`() throws {
        let lastDefaultOrder = try #require(Category.defaults.map(\.sortOrder).max())
        let custom = Domain.Category.custom(name: "Kids", icon: "figure.2.and.child.holdinghands", colorHex: "#000000")

        #expect(custom.isDefault == false)
        #expect(custom.sortOrder > lastDefaultOrder)
        #expect(Category.defaultCategory(for: custom.id) == nil)
    }
}
