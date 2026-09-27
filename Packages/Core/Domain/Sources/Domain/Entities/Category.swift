import Foundation

public struct Category: Identifiable, Equatable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var isDefault: Bool
    public var sortOrder: Int

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        isDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isDefault = isDefault
        self.sortOrder = sortOrder
    }

    public static func custom(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        sortOrder: Int = 100
    ) -> Category {
        Category(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            isDefault: false,
            sortOrder: sortOrder
        )
    }
}

// MARK: - Default Categories

/// Default names are localized when first accessed. Only `id` is persisted (as
/// `Expense.categoryId`), so a name never has to survive a language change.
extension Category {
    // Persisted as `Expense.categoryId` — never change these UUIDs.
    private static let autoTransportId = UUID(uuidString: "D1A00001-0000-0000-0000-000000000001")!
    private static let subscriptionsId = UUID(uuidString: "D1A00002-0000-0000-0000-000000000002")!
    private static let lifestyleId = UUID(uuidString: "D1A00003-0000-0000-0000-000000000003")!
    private static let housingId = UUID(uuidString: "D1A00004-0000-0000-0000-000000000004")!
    private static let petsId = UUID(uuidString: "D1A00005-0000-0000-0000-000000000005")!
    private static let healthFitnessId = UUID(uuidString: "D1A00006-0000-0000-0000-000000000006")!
    private static let foodGroceriesId = UUID(uuidString: "D1A00007-0000-0000-0000-000000000007")!
    private static let entertainmentId = UUID(uuidString: "D1A00008-0000-0000-0000-000000000008")!

    /// Auto & Transportation expenses (gas, insurance, car service, etc.)
    public static let autoTransport = Category(
        id: autoTransportId,
        name: String(localized: "Auto/Transport", bundle: .module),
        icon: "car.fill",
        colorHex: "#3B82F6",
        isDefault: true,
        sortOrder: 0
    )

    /// Recurring subscriptions (streaming, cloud, apps)
    public static let subscriptions = Category(
        id: subscriptionsId,
        name: String(localized: "Subscriptions", bundle: .module),
        icon: "repeat.circle.fill",
        colorHex: "#8B5CF6",
        isDefault: true,
        sortOrder: 1
    )

    /// Daily lifestyle expenses (haircuts, random purchases)
    public static let lifestyle = Category(
        id: lifestyleId,
        name: String(localized: "Lifestyle", bundle: .module),
        icon: "sparkles",
        colorHex: "#F59E0B",
        isDefault: true,
        sortOrder: 2
    )

    /// Housing expenses (rent, utilities)
    public static let housing = Category(
        id: housingId,
        name: String(localized: "Housing", bundle: .module),
        icon: "house.fill",
        colorHex: "#10B981",
        isDefault: true,
        sortOrder: 3
    )

    public static let pets = Category(
        id: petsId,
        name: String(localized: "Pets", bundle: .module),
        icon: "pawprint.fill",
        colorHex: "#EC4899",
        isDefault: true,
        sortOrder: 4
    )

    /// Health and fitness (gym, supplements)
    public static let healthFitness = Category(
        id: healthFitnessId,
        name: String(localized: "Health/Fitness", bundle: .module),
        icon: "heart.fill",
        colorHex: "#EF4444",
        isDefault: true,
        sortOrder: 5
    )

    public static let foodGroceries = Category(
        id: foodGroceriesId,
        name: String(localized: "Food/Groceries", bundle: .module),
        icon: "cart.fill",
        colorHex: "#22C55E",
        isDefault: true,
        sortOrder: 6
    )

    public static let entertainment = Category(
        id: entertainmentId,
        name: String(localized: "Entertainment", bundle: .module),
        icon: "tv.fill",
        colorHex: "#06B6D4",
        isDefault: true,
        sortOrder: 7
    )

    public static let defaults: [Category] = [
        autoTransport,
        subscriptions,
        lifestyle,
        housing,
        pets,
        healthFitness,
        foodGroceries,
        entertainment
    ]

    public static func defaultCategory(for id: UUID) -> Category? {
        defaults.first { $0.id == id }
    }
}
