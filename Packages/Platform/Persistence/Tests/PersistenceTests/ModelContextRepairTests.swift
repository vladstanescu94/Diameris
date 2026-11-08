import Foundation
import SwiftData
import Testing
@testable import Persistence

/// Stores written before onboarding kept account ids have expenses linked to ids that no
/// longer exist. Only an unambiguous case may be repaired.
@MainActor
struct ModelContextRepairTests {
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init() throws {
        container = try makeInMemoryContainer()
    }

    private func insert(accounts: [AccountEntry], expenses: [ExpenseEntry]) throws {
        for (index, account) in accounts.enumerated() {
            context.insert(Account(from: account, sortOrder: index))
        }
        for expense in expenses {
            context.insert(Expense(from: expense))
        }
        try context.save()
    }

    private func links() throws -> [String: UUID?] {
        Dictionary(uniqueKeysWithValues: try context.all(Expense.self).map { ($0.name, $0.linkedAccountId) })
    }

    @Test func oneDanglingIdAndOneJointAccountIsRelinked() throws {
        let joint = AccountEntry.joint()
        let staleJointId = UUID()
        try insert(accounts: [.primary(), joint], expenses: [
            ExpenseEntry(name: "Rent", amount: 1500, icon: "house", linkedAccountId: staleJointId),
            ExpenseEntry(name: "Food", amount: 600, icon: "cart", linkedAccountId: staleJointId),
            ExpenseEntry(name: "Gas", amount: 300, icon: "car")
        ])

        #expect(try context.repairDanglingExpenseLinks() == .relinked(expenseCount: 2))
        #expect(try links() == ["Rent": joint.id, "Food": joint.id, "Gas": nil])
        #expect(try context.repairDanglingExpenseLinks() == .nothingToRepair, "a second run is a no-op")
    }

    @Test func twoDanglingIdsAreLeftUntouched() throws {
        let first = UUID(), second = UUID()
        try insert(accounts: [.primary(), .joint()], expenses: [
            ExpenseEntry(name: "Rent", amount: 1500, icon: "house", linkedAccountId: first),
            ExpenseEntry(name: "Food", amount: 600, icon: "cart", linkedAccountId: second)
        ])

        #expect(try context.repairDanglingExpenseLinks() == .ambiguous(expenseCount: 2, danglingIdCount: 2))
        #expect(try links() == ["Rent": first, "Food": second])
    }

    @Test(arguments: [0, 2])
    func oneDanglingIdWithoutASingleJointAccountIsLeftUntouched(jointCount: Int) throws {
        let staleId = UUID()
        let joints = (0..<jointCount).map { _ in AccountEntry.joint() }
        try insert(accounts: [.primary()] + joints, expenses: [
            ExpenseEntry(name: "Rent", amount: 1500, icon: "house", linkedAccountId: staleId)
        ])

        #expect(try context.repairDanglingExpenseLinks() == .ambiguous(expenseCount: 1, danglingIdCount: 1))
        #expect(try links() == ["Rent": staleId])
    }

    @Test func validLinksAreNeverTouched() throws {
        let joint = AccountEntry.joint()
        let savings = AccountEntry.savings()
        try insert(accounts: [.primary(), joint, savings], expenses: [
            ExpenseEntry(name: "Rent", amount: 1500, icon: "house", linkedAccountId: joint.id),
            ExpenseEntry(name: "Gym", amount: 100, icon: "figure.run", linkedAccountId: savings.id)
        ])

        #expect(try context.repairDanglingExpenseLinks() == .nothingToRepair)
        #expect(try links() == ["Rent": joint.id, "Gym": savings.id])
        #expect(context.hasChanges == false)
    }
}
