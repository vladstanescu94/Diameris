import Foundation

/// Data structure for importing expenses from external sources (like the Python script)
public struct ExpenseImportData: Codable, Sendable {
    public let version: String
    public let exportDate: String
    public let income: IncomeData
    public let savings: SavingsData
    public let emergencyFund: EmergencyFundData
    public let accounts: [AccountData]?
    public let expenses: [ExpenseData]

    public init(
        version: String,
        exportDate: String,
        income: IncomeData,
        savings: SavingsData,
        emergencyFund: EmergencyFundData,
        accounts: [AccountData]? = nil,
        expenses: [ExpenseData]
    ) {
        self.version = version
        self.exportDate = exportDate
        self.income = income
        self.savings = savings
        self.emergencyFund = emergencyFund
        self.accounts = accounts
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

    public struct AccountData: Codable, Sendable {
        public let name: String
        public let accountType: String
        public let isPrimary: Bool
        public let isPrimarySavings: Bool
        public let emergencyMultiplier: Double?
        public let currentBalance: Decimal

        public init(
            name: String,
            accountType: String,
            isPrimary: Bool,
            isPrimarySavings: Bool,
            emergencyMultiplier: Double?,
            currentBalance: Decimal
        ) {
            self.name = name
            self.accountType = accountType
            self.isPrimary = isPrimary
            self.isPrimarySavings = isPrimarySavings
            self.emergencyMultiplier = emergencyMultiplier
            self.currentBalance = currentBalance
        }

        /// Convert string account type to AccountType enum
        public var accountTypeEnum: AccountType {
            switch accountType.lowercased() {
            case "primary": return .primary
            case "emergency": return .emergency
            case "savings": return .savings
            case "personal": return .personal
            case "joint": return .joint
            default: return .primary
            }
        }

        /// Convert to AccountEntry for use in the app
        public func toAccountEntry() -> AccountEntry {
            AccountEntry(
                name: name,
                accountType: accountTypeEnum,
                isPrimary: isPrimary,
                isPrimarySavings: isPrimarySavings,
                emergencyMultiplier: emergencyMultiplier,
                currentBalance: currentBalance
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
