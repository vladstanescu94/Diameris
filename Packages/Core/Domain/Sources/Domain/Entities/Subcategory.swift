import Foundation

/// Subcategory for more granular expense classification
public struct Subcategory: Identifiable, Equatable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var categoryId: UUID
    public var isDefault: Bool
    public var sortOrder: Int

    public init(
        id: UUID = UUID(),
        name: String,
        categoryId: UUID,
        isDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.categoryId = categoryId
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }

    /// Factory method for creating custom subcategories
    public static func custom(
        id: UUID = UUID(),
        name: String,
        categoryId: UUID,
        sortOrder: Int = 100
    ) -> Subcategory {
        Subcategory(
            id: id,
            name: name,
            categoryId: categoryId,
            isDefault: false,
            sortOrder: sortOrder
        )
    }
}

// MARK: - Default Subcategories

extension Subcategory {
    /// Returns default subcategories for a given category
    public static func defaults(for categoryId: UUID) -> [Subcategory] {
        switch categoryId {
        case Category.autoTransport.id:
            return autoTransportDefaults

        case Category.subscriptions.id:
            return subscriptionsDefaults

        case Category.lifestyle.id:
            return lifestyleDefaults

        case Category.housing.id:
            return housingDefaults

        case Category.pets.id:
            return petsDefaults

        case Category.healthFitness.id:
            return healthFitnessDefaults

        case Category.foodGroceries.id:
            return foodGroceriesDefaults

        case Category.entertainment.id:
            return entertainmentDefaults

        default:
            return []
        }
    }

    /// All default subcategories across all categories
    public static var allDefaults: [Subcategory] {
        Category.defaults.flatMap { defaults(for: $0.id) }
    }

    // MARK: - Auto/Transport Subcategories

    private static let autoTransportDefaults: [Subcategory] = [
        Subcategory(
            id: UUID(uuidString: "D2A00001-0001-0000-0000-000000000001")!,
            name: "Gas/Fuel",
            categoryId: Category.autoTransport.id,
            isDefault: true,
            sortOrder: 0
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00001-0002-0000-0000-000000000001")!,
            name: "Car Insurance",
            categoryId: Category.autoTransport.id,
            isDefault: true,
            sortOrder: 1
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00001-0003-0000-0000-000000000001")!,
            name: "Car Service/Repairs",
            categoryId: Category.autoTransport.id,
            isDefault: true,
            sortOrder: 2
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00001-0004-0000-0000-000000000001")!,
            name: "Vehicle Tax",
            categoryId: Category.autoTransport.id,
            isDefault: true,
            sortOrder: 3
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00001-0005-0000-0000-000000000001")!,
            name: "Car Loan/Payment",
            categoryId: Category.autoTransport.id,
            isDefault: true,
            sortOrder: 4
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00001-0006-0000-0000-000000000001")!,
            name: "Public Transport",
            categoryId: Category.autoTransport.id,
            isDefault: true,
            sortOrder: 5
        )
    ]

    // MARK: - Subscriptions Subcategories

    private static let subscriptionsDefaults: [Subcategory] = [
        Subcategory(
            id: UUID(uuidString: "D2A00002-0001-0000-0000-000000000002")!,
            name: "Streaming (Video)",
            categoryId: Category.subscriptions.id,
            isDefault: true,
            sortOrder: 0
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00002-0002-0000-0000-000000000002")!,
            name: "Streaming (Music)",
            categoryId: Category.subscriptions.id,
            isDefault: true,
            sortOrder: 1
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00002-0003-0000-0000-000000000002")!,
            name: "Cloud Storage",
            categoryId: Category.subscriptions.id,
            isDefault: true,
            sortOrder: 2
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00002-0004-0000-0000-000000000002")!,
            name: "Apps/Software",
            categoryId: Category.subscriptions.id,
            isDefault: true,
            sortOrder: 3
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00002-0005-0000-0000-000000000002")!,
            name: "Gaming",
            categoryId: Category.subscriptions.id,
            isDefault: true,
            sortOrder: 4
        )
    ]

    // MARK: - Lifestyle Subcategories

    private static let lifestyleDefaults: [Subcategory] = [
        Subcategory(
            id: UUID(uuidString: "D2A00003-0001-0000-0000-000000000003")!,
            name: "Personal Care",
            categoryId: Category.lifestyle.id,
            isDefault: true,
            sortOrder: 0
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00003-0002-0000-0000-000000000003")!,
            name: "Clothing",
            categoryId: Category.lifestyle.id,
            isDefault: true,
            sortOrder: 1
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00003-0003-0000-0000-000000000003")!,
            name: "Random Expenses",
            categoryId: Category.lifestyle.id,
            isDefault: true,
            sortOrder: 2
        )
    ]

    // MARK: - Housing Subcategories

    private static let housingDefaults: [Subcategory] = [
        Subcategory(
            id: UUID(uuidString: "D2A00004-0001-0000-0000-000000000004")!,
            name: "Rent",
            categoryId: Category.housing.id,
            isDefault: true,
            sortOrder: 0
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00004-0002-0000-0000-000000000004")!,
            name: "Utilities",
            categoryId: Category.housing.id,
            isDefault: true,
            sortOrder: 1
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00004-0003-0000-0000-000000000004")!,
            name: "Internet/Phone",
            categoryId: Category.housing.id,
            isDefault: true,
            sortOrder: 2
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00004-0004-0000-0000-000000000004")!,
            name: "Home Insurance",
            categoryId: Category.housing.id,
            isDefault: true,
            sortOrder: 3
        )
    ]

    // MARK: - Pets Subcategories

    private static let petsDefaults: [Subcategory] = [
        Subcategory(
            id: UUID(uuidString: "D2A00005-0001-0000-0000-000000000005")!,
            name: "Pet Food",
            categoryId: Category.pets.id,
            isDefault: true,
            sortOrder: 0
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00005-0002-0000-0000-000000000005")!,
            name: "Pet Supplies",
            categoryId: Category.pets.id,
            isDefault: true,
            sortOrder: 1
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00005-0003-0000-0000-000000000005")!,
            name: "Vet/Medical",
            categoryId: Category.pets.id,
            isDefault: true,
            sortOrder: 2
        )
    ]

    // MARK: - Health/Fitness Subcategories

    private static let healthFitnessDefaults: [Subcategory] = [
        Subcategory(
            id: UUID(uuidString: "D2A00006-0001-0000-0000-000000000006")!,
            name: "Gym Membership",
            categoryId: Category.healthFitness.id,
            isDefault: true,
            sortOrder: 0
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00006-0002-0000-0000-000000000006")!,
            name: "Supplements",
            categoryId: Category.healthFitness.id,
            isDefault: true,
            sortOrder: 1
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00006-0003-0000-0000-000000000006")!,
            name: "Medical/Healthcare",
            categoryId: Category.healthFitness.id,
            isDefault: true,
            sortOrder: 2
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00006-0004-0000-0000-000000000006")!,
            name: "Pharmacy",
            categoryId: Category.healthFitness.id,
            isDefault: true,
            sortOrder: 3
        )
    ]

    // MARK: - Food/Groceries Subcategories

    private static let foodGroceriesDefaults: [Subcategory] = [
        Subcategory(
            id: UUID(uuidString: "D2A00007-0001-0000-0000-000000000007")!,
            name: "Groceries",
            categoryId: Category.foodGroceries.id,
            isDefault: true,
            sortOrder: 0
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00007-0002-0000-0000-000000000007")!,
            name: "Restaurants",
            categoryId: Category.foodGroceries.id,
            isDefault: true,
            sortOrder: 1
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00007-0003-0000-0000-000000000007")!,
            name: "Delivery/Takeout",
            categoryId: Category.foodGroceries.id,
            isDefault: true,
            sortOrder: 2
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00007-0004-0000-0000-000000000007")!,
            name: "Coffee/Snacks",
            categoryId: Category.foodGroceries.id,
            isDefault: true,
            sortOrder: 3
        )
    ]

    // MARK: - Entertainment Subcategories

    private static let entertainmentDefaults: [Subcategory] = [
        Subcategory(
            id: UUID(uuidString: "D2A00008-0001-0000-0000-000000000008")!,
            name: "Movies/Cinema",
            categoryId: Category.entertainment.id,
            isDefault: true,
            sortOrder: 0
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00008-0002-0000-0000-000000000008")!,
            name: "Events/Concerts",
            categoryId: Category.entertainment.id,
            isDefault: true,
            sortOrder: 1
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00008-0003-0000-0000-000000000008")!,
            name: "Hobbies",
            categoryId: Category.entertainment.id,
            isDefault: true,
            sortOrder: 2
        ),
        Subcategory(
            id: UUID(uuidString: "D2A00008-0004-0000-0000-000000000008")!,
            name: "Travel/Vacation",
            categoryId: Category.entertainment.id,
            isDefault: true,
            sortOrder: 3
        )
    ]
}
