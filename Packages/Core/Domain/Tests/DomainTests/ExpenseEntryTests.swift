import Foundation
import Testing
@testable import Domain

struct ExpenseEntryTests {

    @Test(arguments: [
        (Decimal(1200), Frequency.annual, Decimal(100), Decimal(1200)),
        (Decimal(450), .monthly, Decimal(450), Decimal(5400)),
        (Decimal(string: "359.88")!, .annual, Decimal(string: "29.99")!, Decimal(string: "359.88")!)
    ])
    func `Monthly and annual equivalents are exact for amounts divisible by 12`(
        amount: Decimal,
        frequency: Frequency,
        monthly: Decimal,
        annual: Decimal
    ) {
        let expense = Fixture.expense("Insurance", amount, frequency)

        #expect(expense.monthlyAmount == monthly, "1200 × (1/12) would be 99.999…96")
        #expect(expense.annualAmount == annual)
        #expect(expense.displayAmount(for: .monthly) == monthly)
        #expect(expense.displayAmount(for: .annual) == annual)
    }

    @Test func `Totals count enabled expenses only, normalised to the requested period`() {
        let expenses = [
            Fixture.expense("Rent", 2500),
            Fixture.expense("Insurance", 1200, .annual),
            Fixture.expense("Gym", 200, enabled: false)
        ]

        #expect(expenses.totalMonthly == 2600)
        #expect(expenses.totalAnnual == 31_200)
    }

    @Test(arguments: zip([Decimal(2600), 0, -5, 100], [650.0 / 2600, 0, 0, 1]))
    func `Share of total is a clamped fraction`(total: Decimal, expected: Double) {
        #expect(Fixture.expense("Food", 650).share(ofTotal: total) == expected)
    }

    @Test(arguments: [
        ("Rent", Decimal(2500), ExpenseEntry.ValidationError?.none),
        ("Paused gym", 0, nil),
        ("   ", 100, .nameMissing),
        (String(repeating: "a", count: 101), 100, .nameTooLong),
        (String(repeating: "a", count: 100), 10_000_000, nil),
        ("Rent", -1, .amountNegative),
        ("Rent", 10_000_001, .amountTooHigh)
    ])
    func `Validation follows the expense spec`(name: String, amount: Decimal, error: ExpenseEntry.ValidationError?) {
        #expect(ExpenseEntry.validationError(name: name, amount: amount) == error)
        #expect(ExpenseEntry.isValid(name: name, amount: amount) == (error == nil))
    }

    @Test func `Category resolves only for default category ids`() {
        var expense = Fixture.expense("Rent", 2500)
        #expect(expense.category() == nil)

        expense.categoryId = Category.housing.id
        #expect(expense.category() == .housing)

        expense.categoryId = UUID()
        #expect(expense.category() == nil)
    }
}
