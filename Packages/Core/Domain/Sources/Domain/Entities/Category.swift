import Foundation

/// Expense category for grouping and analysis
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

    /// Factory method for creating custom categories
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

extension Category {
    // Stable UUIDs for default categories (ensures consistency across app launches)
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
        name: "Auto/Transport",
        icon: "car.fill",
        colorHex: "#3B82F6", // Blue
        isDefault: true,
        sortOrder: 0
    )

    /// Recurring subscriptions (streaming, cloud, apps)
    public static let subscriptions = Category(
        id: subscriptionsId,
        name: "Subscriptions",
        icon: "repeat.circle.fill",
        colorHex: "#8B5CF6", // Purple
        isDefault: true,
        sortOrder: 1
    )

    /// Daily lifestyle expenses (haircuts, random purchases)
    public static let lifestyle = Category(
        id: lifestyleId,
        name: "Lifestyle",
        icon: "sparkles",
        colorHex: "#F59E0B", // Amber
        isDefault: true,
        sortOrder: 2
    )

    /// Housing expenses (rent, utilities)
    public static let housing = Category(
        id: housingId,
        name: "Housing",
        icon: "house.fill",
        colorHex: "#10B981", // Emerald
        isDefault: true,
        sortOrder: 3
    )

    /// Pet-related expenses
    public static let pets = Category(
        id: petsId,
        name: "Pets",
        icon: "pawprint.fill",
        colorHex: "#EC4899", // Pink
        isDefault: true,
        sortOrder: 4
    )

    /// Health and fitness (gym, supplements)
    public static let healthFitness = Category(
        id: healthFitnessId,
        name: "Health/Fitness",
        icon: "heart.fill",
        colorHex: "#EF4444", // Red
        isDefault: true,
        sortOrder: 5
    )

    /// Food and groceries
    public static let foodGroceries = Category(
        id: foodGroceriesId,
        name: "Food/Groceries",
        icon: "cart.fill",
        colorHex: "#22C55E", // Green
        isDefault: true,
        sortOrder: 6
    )

    /// Entertainment and leisure
    public static let entertainment = Category(
        id: entertainmentId,
        name: "Entertainment",
        icon: "tv.fill",
        colorHex: "#06B6D4", // Cyan
        isDefault: true,
        sortOrder: 7
    )

    /// All predefined default categories
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

    /// Find a default category by ID
    public static func defaultCategory(for id: UUID) -> Category? {
        defaults.first { $0.id == id }
    }
}
