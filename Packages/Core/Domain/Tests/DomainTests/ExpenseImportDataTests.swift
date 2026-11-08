import Foundation
import Testing
@testable import Domain

struct ExpenseImportDataTests {

    static let json = """
    {
      "version": "1", "exportDate": "2026-09-01",
      "income": { "amount": 8500, "frequency": "monthly", "name": "Salary" },
      "savings": { "percentage": 0.25, "boostEnabled": false, "boostMultiplier": 3 },
      "emergencyFund": { "currentBalance": 1000, "targetMultiplier": 3 },
      "accounts": [
        { "name": "ING", "accountType": "Primary", "isPrimary": true, "isPrimarySavings": false,
          "emergencyMultiplier": null, "currentBalance": 0 },
        { "name": "Kids", "accountType": "other", "isPrimary": false, "isPrimarySavings": false,
          "emergencyMultiplier": null, "currentBalance": 50 },
        { "name": "Crypto", "accountType": "brokerage", "isPrimary": false, "isPrimarySavings": false,
          "emergencyMultiplier": null, "currentBalance": 0 }
      ],
      "expenses": [
        { "name": "RCA", "amount": 1200, "frequency": "annual", "icon": "car.fill",
          "categoryId": "D1A00001-0000-0000-0000-000000000001", "isEnabled": true },
        { "name": "Gym", "amount": 150, "frequency": "monthly", "icon": "heart.fill",
          "categoryId": "not-a-uuid", "isEnabled": false }
      ]
    }
    """

    @Test func `Import converts expenses with frequency, category and enabled state`() throws {
        let data = try ExpenseImportData.parse(from: Self.json)
        let entries = data.expenses.map { $0.toExpenseEntry() }

        #expect(entries.map(\.monthlyAmount) == [100, 150])
        #expect(entries.first?.category() == .autoTransport)
        #expect(entries.last?.categoryId == nil)
        #expect(entries.map(\.isEnabled) == [true, false])
    }

    @Test func `Unknown account types import as other, never as a second primary`() throws {
        let data = try ExpenseImportData.parse(from: Self.json)
        let types = try #require(data.accounts).map(\.accountTypeEnum)

        #expect(types == [.primary, .other, .other])
    }

    @Test func `Malformed JSON throws a decoding error`() {
        #expect(throws: DecodingError.self) {
            try ExpenseImportData.parse(from: "{ \"version\": 1 }")
        }
    }
}
