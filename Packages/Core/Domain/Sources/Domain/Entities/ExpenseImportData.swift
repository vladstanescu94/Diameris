import Foundation

/// Data structure for importing expenses from external sources (like the Python script)
public struct ExpenseImportData: Codable, Sendable {
    public let version: String
    public let exportDate: String
    public let income: IncomeData
    public let savings: SavingsData
    public let emergencyFund: EmergencyFundData
    public let expenses: [ExpenseData]

    public init(
        version: String,
        exportDate: String,
        income: IncomeData,
        savings: SavingsData,
        emergencyFund: EmergencyFundData,
        expenses: [ExpenseData]
    ) {
        self.version = version
        self.exportDate = exportDate
        self.income = income
        self.savings = savings
        self.emergencyFund = emergencyFund
        self.expenses = expenses
    }
}

// MARK: - Nested Types

extension ExpenseImportData {
    public struct IncomeData: Codable, Sendable {
        public let amount: Decimal
        public let frequency: String
        public let name: String

        public init(amount: Decimal, frequency: String, name: String) {
            self.amount = amount
            self.frequency = frequency
            self.name = name
        }
    }

    public struct SavingsData: Codable, Sendable {
        public let percentage: Double
        public let boostEnabled: Bool
        public let boostMultiplier: Int

        public init(percentage: Double, boostEnabled: Bool, boostMultiplier: Int) {
            self.percentage = percentage
            self.boostEnabled = boostEnabled
            self.boostMultiplier = boostMultiplier
        }
    }

    public struct EmergencyFundData: Codable, Sendable {
        public let currentBalance: Decimal
        public let targetMultiplier: Double

        public init(currentBalance: Decimal, targetMultiplier: Double) {
            self.currentBalance = currentBalance
            self.targetMultiplier = targetMultiplier
        }
    }

    public struct ExpenseData: Codable, Sendable {
        public let name: String
        public let amount: Decimal
        public let frequency: String
        public let icon: String
        public let categoryId: String?
        public let isEnabled: Bool

        public init(
            name: String,
            amount: Decimal,
            frequency: String,
            icon: String,
            categoryId: String?,
            isEnabled: Bool
        ) {
            self.name = name
            self.amount = amount
            self.frequency = frequency
            self.icon = icon
            self.categoryId = categoryId
            self.isEnabled = isEnabled
        }

        /// Convert to ExpenseEntry for use in the app
        public func toExpenseEntry() -> ExpenseEntry {
            let freq = frequency == "annual" ? Frequency.annual : Frequency.monthly
            let catId = categoryId.flatMap { UUID(uuidString: $0) }

            return ExpenseEntry(
                name: name,
                amount: amount,
                frequency: freq,
                icon: icon,
                categoryId: catId,
                isEnabled: isEnabled
            )
        }
    }
}

// MARK: - Parsing

extension ExpenseImportData {
    /// Parse JSON string into ExpenseImportData
    public static func parse(from jsonString: String) throws -> ExpenseImportData {
        guard let data = jsonString.data(using: .utf8) else {
            throw ImportError.invalidData
        }
        return try JSONDecoder().decode(ExpenseImportData.self, from: data)
    }

    /// Parse JSON data into ExpenseImportData
    public static func parse(from data: Data) throws -> ExpenseImportData {
        try JSONDecoder().decode(ExpenseImportData.self, from: data)
    }

    public enum ImportError: Error, LocalizedError {
        case invalidData
        case decodingFailed(Error)

        public var errorDescription: String? {
            switch self {
            case .invalidData:
                return "Invalid JSON data"
            case .decodingFailed(let error):
                return "Failed to decode: \(error.localizedDescription)"
            }
        }
    }
}
