import Foundation
import Testing
@testable import Domain

/// Tests for Subcategory struct - validates default subcategories,
/// category associations, and factory methods.
@Suite("Subcategory Tests")
struct SubcategoryTests {

    // MARK: - Default Subcategories

    @Suite("Default Subcategories")
    struct DefaultSubcategoriesTests {

        @Test("Auto/Transport has subcategories")
        func autoTransportHasSubcategories() {
            let subs = Subcategory.defaults(for: Category.autoTransport.id)
            #expect(!subs.isEmpty)
            #expect(subs.count >= 5) // Gas, Insurance, Service, Tax, Loan, Transport
        }

        @Test("Subscriptions has subcategories")
        func subscriptionsHasSubcategories() {
            let subs = Subcategory.defaults(for: Category.subscriptions.id)
            #expect(!subs.isEmpty)
        }

        @Test("All default categories have subcategories")
        func allCategoriesHaveSubcategories() {
            for category in Category.defaults {
                let subs = Subcategory.defaults(for: category.id)
                #expect(!subs.isEmpty, "Category \(category.name) should have subcategories")
            }
        }

        @Test("Unknown category ID returns empty array")
        func unknownCategoryReturnsEmpty() {
            let subs = Subcategory.defaults(for: UUID())
            #expect(subs.isEmpty)
        }

        @Test("allDefaults returns subcategories for all categories")
        func allDefaultsReturnsAll() {
            let all = Subcategory.allDefaults
            #expect(!all.isEmpty)

            // Should have subcategories from multiple categories
            let categoryIds = Set(all.map { $0.categoryId })
            #expect(categoryIds.count == Category.defaults.count)
        }
    }

    // MARK: - Subcategory Properties

    @Suite("Subcategory Properties")
    struct PropertiesTests {

        @Test("All defaults have isDefault true")
        func allDefaultsMarked() {
            for sub in Subcategory.allDefaults {
                #expect(sub.isDefault == true)
            }
        }

        @Test("All defaults have non-empty names")
        func nonEmptyNames() {
            for sub in Subcategory.allDefaults {
                #expect(!sub.name.isEmpty)
            }
        }

        @Test("All defaults have valid category IDs")
        func validCategoryIds() {
            for sub in Subcategory.allDefaults {
                let category = Category.defaultCategory(for: sub.categoryId)
                #expect(category != nil, "Subcategory \(sub.name) has invalid categoryId")
            }
        }

        @Test("Subcategories within a category have unique names")
        func uniqueNamesWithinCategory() {
            for category in Category.defaults {
                let subs = Subcategory.defaults(for: category.id)
                let names = subs.map { $0.name }
                let uniqueNames = Set(names)
                #expect(names.count == uniqueNames.count,
                        "Category \(category.name) has duplicate subcategory names")
            }
        }

        @Test("Subcategories within a category are sorted by sortOrder")
        func sortedBySortOrder() {
            for category in Category.defaults {
                let subs = Subcategory.defaults(for: category.id)
                let sortOrders = subs.map { $0.sortOrder }
                let sorted = sortOrders.sorted()
                #expect(sortOrders == sorted,
                        "Category \(category.name) subcategories not sorted")
            }
        }
    }

    // MARK: - Stable UUIDs

    @Suite("Stable UUIDs")
    struct StableUUIDsTests {

        @Test("Subcategory IDs are deterministic")
        func deterministicIds() {
            let snapshot1 = Subcategory.defaults(for: Category.autoTransport.id).map { $0.id }
            let snapshot2 = Subcategory.defaults(for: Category.autoTransport.id).map { $0.id }
            #expect(snapshot1 == snapshot2)
        }

        @Test("All default subcategories have unique IDs globally")
        func globallyUniqueIds() {
            let allIds = Subcategory.allDefaults.map { $0.id }
            let uniqueIds = Set(allIds)
            #expect(allIds.count == uniqueIds.count)
        }
    }

    // MARK: - Custom Subcategory Factory

    @Suite("Custom Subcategory Factory")
    struct CustomSubcategoryTests {

        @Test("Custom factory creates non-default subcategory")
        func customIsNotDefault() {
            let custom = Subcategory.custom(
                name: "Custom Sub",
                categoryId: Category.autoTransport.id
            )
            #expect(custom.isDefault == false)
        }

        @Test("Custom factory generates unique ID")
        func customUniqueId() {
            let custom1 = Subcategory.custom(name: "A", categoryId: Category.autoTransport.id)
            let custom2 = Subcategory.custom(name: "B", categoryId: Category.autoTransport.id)
            #expect(custom1.id != custom2.id)
        }

        @Test("Custom factory uses provided values")
        func customUsesProvidedValues() {
            let categoryId = Category.subscriptions.id
            let custom = Subcategory.custom(
                name: "Test Sub",
                categoryId: categoryId,
                sortOrder: 50
            )
            #expect(custom.name == "Test Sub")
            #expect(custom.categoryId == categoryId)
            #expect(custom.sortOrder == 50)
        }

        @Test("Custom factory default sortOrder is 100")
        func customDefaultSortOrder() {
            let custom = Subcategory.custom(name: "A", categoryId: UUID())
            #expect(custom.sortOrder == 100)
        }
    }

    // MARK: - Specific Subcategories

    @Suite("Specific Default Subcategories")
    struct SpecificSubcategoriesTests {

        @Test("Auto/Transport contains Gas/Fuel")
        func autoHasGas() {
            let subs = Subcategory.defaults(for: Category.autoTransport.id)
            let gas = subs.first { $0.name == "Gas/Fuel" }
            #expect(gas != nil)
        }

        @Test("Auto/Transport contains Car Insurance")
        func autoHasInsurance() {
            let subs = Subcategory.defaults(for: Category.autoTransport.id)
            let insurance = subs.first { $0.name == "Car Insurance" }
            #expect(insurance != nil)
        }

        @Test("Subscriptions contains Streaming (Video)")
        func subscriptionsHasStreaming() {
            let subs = Subcategory.defaults(for: Category.subscriptions.id)
            let streaming = subs.first { $0.name.contains("Streaming") }
            #expect(streaming != nil)
        }

        @Test("Pets contains Pet Food")
        func petsHasPetFood() {
            let subs = Subcategory.defaults(for: Category.pets.id)
            let food = subs.first { $0.name == "Pet Food" }
            #expect(food != nil)
        }

        @Test("Health/Fitness contains Gym Membership")
        func healthHasGym() {
            let subs = Subcategory.defaults(for: Category.healthFitness.id)
            let gym = subs.first { $0.name == "Gym Membership" }
            #expect(gym != nil)
        }
    }

    // MARK: - Hashable & Equatable

    @Suite("Hashable & Equatable")
    struct HashableEquatableTests {

        @Test("Same subcategory is equal")
        func sameIsEqual() {
            let subs = Subcategory.defaults(for: Category.autoTransport.id)
            guard let sub1 = subs.first, let sub2 = subs.first else {
                Issue.record("No subcategories found")
                return
            }
            #expect(sub1 == sub2)
        }

        @Test("Different subcategories are not equal")
        func differentNotEqual() {
            let subs = Subcategory.defaults(for: Category.autoTransport.id)
            guard subs.count >= 2 else {
                Issue.record("Need at least 2 subcategories")
                return
            }
            #expect(subs[0] != subs[1])
        }

        @Test("Can be used in Set")
        func usableInSet() {
            let subs = Subcategory.defaults(for: Category.autoTransport.id)
            var set = Set<Subcategory>()
            for sub in subs {
                set.insert(sub)
            }
            #expect(set.count == subs.count)
        }
    }
}
