import Foundation
import SwiftData
import Domain

/// Outcome of `repairDanglingExpenseLinks()`, for the caller to log.
public enum ExpenseLinkRepair: Equatable, Sendable {
    case nothingToRepair
    case relinked(expenseCount: Int)
    /// Links left as they are: more than one dangling id, or not exactly one Joint account.
    case ambiguous(expenseCount: Int, danglingIdCount: Int)
}

public extension ModelContext {
    /// Repairs expenses whose `linkedAccountId` points at no stored account.
    ///
    /// Onboarding used to store accounts under fresh ids, orphaning every link made there. When
    /// the answer is unambiguous (one dangling id and exactly one Joint account, the documented
    /// use case) the expenses are relinked to that Joint account. Otherwise nothing changes: the
    /// dangling id is the only record of the user's intent. Safe to run on every launch.
    @discardableResult
    func repairDanglingExpenseLinks() throws -> ExpenseLinkRepair {
        let accounts = try fetch(FetchDescriptor<Account>())
        let accountIds = Set(accounts.map(\.id))
        let dangling = try fetch(FetchDescriptor<Expense>()).filter { expense in
            expense.linkedAccountId.map { !accountIds.contains($0) } ?? false
        }
        guard !dangling.isEmpty else { return .nothingToRepair }

        let danglingIds = Set(dangling.compactMap(\.linkedAccountId))
        let jointAccounts = accounts.filter { $0.accountType == .joint }
        guard danglingIds.count == 1, jointAccounts.count == 1, let joint = jointAccounts.first else {
            return .ambiguous(expenseCount: dangling.count, danglingIdCount: danglingIds.count)
        }

        for expense in dangling {
            expense.linkedAccountId = joint.id
        }
        try commit()
        return .relinked(expenseCount: dangling.count)
    }
}

public extension ModelContext {
    /// If the onboarding flag is lost while the store survives, onboarding would reappear and its
    /// save would replace the user's data. A stored profile proves onboarding finished.
    /// - Returns: Whether the flag was restored.
    @discardableResult
    func restoreOnboardingFlag(in defaults: UserDefaults, forKey key: String) throws -> Bool {
        guard !defaults.bool(forKey: key), try fetchCount(FetchDescriptor<UserProfile>()) > 0 else { return false }
        defaults.set(true, forKey: key)
        return true
    }
}
