import Foundation
import Testing
@testable import Domain

// Disambiguate from any potential Testing framework Category type
typealias ExpenseCategory = Domain.Category

/// Tests for Category struct - validates default categories,
/// stable UUIDs, and factory methods.
@Suite("Category Tests")
struct CategoryTests {

    // MARK: - Default Categories

    @Suite("Default Categories")
    struct DefaultCategoriesTests {

        @Test("Has 8 default categories")
        func hasEightDefaults() {
            #expect(Category.defaults.count == 8)
        }

        @Test("All defaults have isDefault true")
        func allDefaultsMarked() {
            for category in Category.defaults {
                #expect(category.isDefault == true, "Category \(category.name) should be marked as default")
            }
        }

        @Test("Default categories have unique IDs")
        func uniqueIds() {
            let ids = Category.defaults.map { $0.id }
            let uniqueIds = Set(ids)
            #expect(ids.count == uniqueIds.count)
        }

        @Test("Default categories have unique names")
        func uniqueNames() {
            let names = Category.defaults.map { $0.name }
            let uniqueNames = Set(names)
            #expect(names.count == uniqueNames.count)
        }

        @Test("Default categories are sorted by sortOrder")
        func sortedBySortOrder() {
            let sortOrders = Category.defaults.map { $0.sortOrder }
            let sorted = sortOrders.sorted()
            #expect(sortOrders == sorted)
        }

        @Test("Auto/Transport is first default")
        func autoTransportFirst() {
            #expect(Category.defaults.first?.id == Category.autoTransport.id)
        }
    }

    // MARK: - Stable UUIDs

    @Suite("Stable UUIDs")
    struct StableUUIDsTests {

        @Test("Auto/Transport has stable UUID")
        func autoTransportStableId() {
            let id1 = Category.autoTransport.id
            let id2 = Category.autoTransport.id
            #expect(id1 == id2)
        }

        @Test("All default category IDs are deterministic")
        func deterministicIds() {
            // Create a snapshot of IDs
            let snapshot1 = Category.defaults.map { $0.id }
            let snapshot2 = Category.defaults.map { $0.id }
            #expect(snapshot1 == snapshot2)
        }

        @Test("Default category lookup by ID works")
        func lookupById() {
            let category = Category.defaultCategory(for: Category.autoTransport.id)
            #expect(category != nil)
            #expect(category?.name == "Auto/Transport")
        }

        @Test("Lookup returns nil for unknown ID")
        func lookupUnknownId() {
            let result = Category.defaultCategory(for: UUID())
            #expect(result == nil)
        }
    }

    // MARK: - Category Properties

    @Suite("Category Properties")
    struct PropertiesTests {

        @Test("All defaults have non-empty names")
        func nonEmptyNames() {
            for category in Category.defaults {
                #expect(!category.name.isEmpty)
            }
        }

        @Test("All defaults have non-empty icons")
        func nonEmptyIcons() {
            for category in Category.defaults {
                #expect(!category.icon.isEmpty)
            }
        }

        @Test("All defaults have valid hex colors")
        func validHexColors() {
            let hexPattern = /^#[0-9A-Fa-f]{6}$/
            for category in Category.defaults {
                #expect(category.colorHex.contains(hexPattern), "Invalid hex color: \(category.colorHex)")
            }
        }

        @Test("Icons are SF Symbol format (contain .fill or similar)")
        func iconFormat() {
            // Most category icons should be SF Symbols
            let validIcons = Category.defaults.filter { icon in
                icon.icon.contains(".") || icon.icon == "sparkles"
            }
            #expect(validIcons.count >= 6, "Most icons should be SF Symbol format")
        }
    }

    // MARK: - Custom Category Factory

    @Suite("Custom Category Factory")
    struct CustomCategoryTests {

        @Test("Custom factory creates non-default category")
        func customIsNotDefault() {
            let custom = Category.custom(
                name: "Custom",
                icon: "star.fill",
                colorHex: "#FF0000"
            )
            #expect(custom.isDefault == false)
        }

        @Test("Custom factory generates unique ID")
        func customUniqueId() {
            let custom1 = Category.custom(name: "A", icon: "star", colorHex: "#000")
            let custom2 = Category.custom(name: "B", icon: "star", colorHex: "#000")
            #expect(custom1.id != custom2.id)
        }

        @Test("Custom factory uses provided values")
        func customUsesProvidedValues() {
            let custom = Category.custom(
                name: "Test Category",
                icon: "star.fill",
                colorHex: "#123456",
                sortOrder: 50
            )
            #expect(custom.name == "Test Category")
            #expect(custom.icon == "star.fill")
            #expect(custom.colorHex == "#123456")
            #expect(custom.sortOrder == 50)
        }

        @Test("Custom factory default sortOrder is 100")
        func customDefaultSortOrder() {
            let custom = Category.custom(name: "A", icon: "star", colorHex: "#000")
            #expect(custom.sortOrder == 100)
        }
    }

    // MARK: - Specific Categories

    @Suite("Specific Default Categories")
    struct SpecificCategoriesTests {

        @Test("Auto/Transport properties")
        func autoTransportProperties() {
            let cat = Category.autoTransport
            #expect(cat.name == "Auto/Transport")
            #expect(cat.icon == "car.fill")
            #expect(cat.sortOrder == 0)
        }

        @Test("Subscriptions properties")
        func subscriptionsProperties() {
            let cat = Category.subscriptions
            #expect(cat.name == "Subscriptions")
            #expect(cat.icon == "repeat.circle.fill")
        }

        @Test("Pets properties")
        func petsProperties() {
            let cat = Category.pets
            #expect(cat.name == "Pets")
            #expect(cat.icon == "pawprint.fill")
        }

        @Test("Food/Groceries properties")
        func foodGroceriesProperties() {
            let cat = Category.foodGroceries
            #expect(cat.name == "Food/Groceries")
            #expect(cat.icon == "cart.fill")
        }
    }

    // MARK: - Hashable & Equatable

    @Suite("Hashable & Equatable")
    struct HashableEquatableTests {

        @Test("Same category is equal")
        func sameIsEqual() {
            let cat1 = Category.autoTransport
            let cat2 = Category.autoTransport
            #expect(cat1 == cat2)
        }

        @Test("Different categories are not equal")
        func differentNotEqual() {
            #expect(Category.autoTransport != Category.subscriptions)
        }

        @Test("Can be used in Set")
        func usableInSet() {
            var set = Set<ExpenseCategory>()
            set.insert(ExpenseCategory.autoTransport)
            set.insert(ExpenseCategory.subscriptions)
            set.insert(ExpenseCategory.autoTransport) // Duplicate

            #expect(set.count == 2)
        }

        @Test("Can be used as Dictionary key")
        func usableAsDictionaryKey() {
            var dict: [ExpenseCategory: Int] = [:]
            dict[ExpenseCategory.autoTransport] = 100
            dict[ExpenseCategory.subscriptions] = 200

            #expect(dict[ExpenseCategory.autoTransport] == 100)
        }
    }
}
