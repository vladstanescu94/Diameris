import Domain
import Foundation
import Utilities
import Vapor

// The test oracle for `Web/Docs/golden-vectors.json` (R11).
//
// Takes a scenario `input` and returns the computed outputs keyed with the **exact** names the
// fixture's `expected` blocks use, so the Reviewer's harness can do a recursive key lookup and
// assert equality without translating field paths. Persists nothing.

public struct GoldenScenarioPayload: Content, Sendable {
    public var monthlyIncome: DecimalString
    public var savings: GoldenSavings?
    public var accounts: [GoldenAccount]
    public var expenses: [GoldenExpense]
    public var remainingMoneyDestination: RemainingMoneyDestination?
    /// `"onboarding"` | `"established"` — declares whether the scenario describes a user who has
    /// just made their first transfers (so the plan is applied and the dashboard shows the result)
    /// or a pre-existing state to be read as-is.
    ///
    /// Explicit rather than inferred: "all balances zero" looks identical for a fresh user and a
    /// returning one who has spent everything, but the intended reading is opposite.
    public var phase: String?
    /// Runs a New Month cycle on top of the month-1 result, for chained scenarios.
    public var newMonth: GoldenNewMonth?

    /// The base scenario for a chained vector (`continuesFrom` in the fixture), supplied **inline**
    /// as a one-element array.
    ///
    /// Inline rather than a scenario id so the oracle never reads `golden-vectors.json` and stays a
    /// pure function of its input. An array because a Swift `struct` cannot contain itself
    /// directly; treat it as `GoldenScenarioPayload?`.
    ///
    /// The base is replayed in full — including applying its plan when its own `phase` says to —
    /// and this scenario's `newMonth` then runs against the resulting balances. A base carrying its
    /// own `continuesFrom` is replayed recursively.
    public var continuesFrom: [GoldenScenarioPayload]?

    var base: GoldenScenarioPayload? { continuesFrom?.first }

    public struct GoldenAccount: Content, Sendable {
        /// Fixture-local key (`"main"`, `"emergency"`), mapped to a stable UUID so
        /// `linkedAccountId` can reference it by the same string.
        public var id: String
        public var name: String
        public var type: AccountType
        public var currentBalance: DecimalString?
        public var emergencyMultiplier: Double?
        public var emergencyHardCap: DecimalString?
        public var isPrimarySavings: Bool?
    }

    public struct GoldenExpense: Content, Sendable {
        public var id: String?
        public var name: String
        public var amount: DecimalString
        public var frequency: Frequency?
        public var isEnabled: Bool?
        public var categoryId: String?
        /// Fixture-local account key, or omitted/`"main"` for the primary account.
        public var linkedAccountId: String?
    }

    /// Split uses two independent per-side blocks; priority uses `mode`/`percentage`/`fixedAmount`.
    public struct GoldenSavings: Content, Sendable {
        public var strategy: String?
        public var mode: String?
        /// Whole percent, e.g. `25` — **not** `0.25`. The fixture speaks in percent.
        public var percentage: Double?
        public var fixedAmount: DecimalString?
        public var boost: Bool?
        public var boostMultiplier: Double?
        public var emergency: GoldenSplitSide?
        public var savings: GoldenSplitSide?

        public struct GoldenSplitSide: Content, Sendable {
            public var mode: String?
            public var percentage: Double?
            public var fixedAmount: DecimalString?
        }
    }

    public struct GoldenNewMonth: Content, Sendable {
        public var income: DecimalString
        /// Account-key → balance. Deliberately partial in S16, to exercise the R10 guard.
        public var accountBalancesEnteredByUser: [String: DecimalString]?
    }
}

public struct GoldenResultResponse: Content, Sendable {
    public let raw: [String: String]
    public let display: [String: String]
    public let percent: [String: Int]
    public let flags: [String: Bool]
    /// Fixture-key → the UUID it was mapped to, so a failing assertion is traceable.
    public let accountIds: [String: String]
}

public enum GoldenService {

    /// Deterministic UUID per fixture key, so a scenario is reproducible run to run.
    static func uuid(for key: String) -> UUID {
        var bytes = [UInt8](repeating: 0, count: 16)
        let source = Array(key.utf8)
        for (index, byte) in source.enumerated() where index < 16 {
            bytes[index] = byte
        }
        // Stamp a recognisable prefix so these are obviously synthetic in any dump.
        bytes[0] = 0x0D
        let hex = bytes.map { String(format: "%02x", $0) }.joined()
        let parts = [
            hex.prefix(8),
            hex.dropFirst(8).prefix(4),
            hex.dropFirst(12).prefix(4),
            hex.dropFirst(16).prefix(4),
            hex.dropFirst(20).prefix(12)
        ]
        return UUID(uuidString: parts.joined(separator: "-")) ?? UUID()
    }

    /// Fixture category slugs (`"food-groceries"`) → the real `Domain.Category` UUIDs. Without
    /// this an expense's `categoryId` points at a synthetic UUID, no category group forms, and the
    /// Expenses-tab counters silently go missing.
    static func categoryId(for slug: String) -> UUID {
        func slugify(_ name: String) -> String {
            name.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
                .joined(separator: "-")
        }
        if let match = Domain.Category.defaults.first(where: { slugify($0.name) == slug }) {
            return match.id
        }
        return uuid(for: slug)
    }

    static func allocation(from payload: GoldenScenarioPayload.GoldenSavings?) -> SavingsAllocationEntry {
        var entry = SavingsAllocationEntry()
        guard let payload else { return entry }

        entry.allocationMode = payload.strategy == "split" ? .split : .prioritized
        entry.boostEnabled = payload.boost ?? false
        if let multiplier = payload.boostMultiplier { entry.boostMultiplier = multiplier }

        // Fixture percentages are whole numbers (25), Domain wants fractions (0.25).
        if let percentage = payload.percentage { entry.percentage = percentage / 100 }
        if let fixed = payload.fixedAmount { entry.fixedAmount = fixed.value }
        entry.savingsInputMode = payload.mode == "fixed" ? .fixedAmount : .percentage

        if let emergency = payload.emergency {
            entry.splitEmergencyInputMode = emergency.mode == "fixed" ? .fixedAmount : .percentage
            if let percentage = emergency.percentage { entry.splitEmergencyPercentage = percentage / 100 }
            if let fixed = emergency.fixedAmount { entry.splitEmergencyAmount = fixed.value }
        }
        if let savings = payload.savings {
            entry.splitSavingsInputMode = savings.mode == "fixed" ? .fixedAmount : .percentage
            if let percentage = savings.percentage { entry.splitSavingsPercentage = percentage / 100 }
            if let fixed = savings.fixedAmount { entry.splitSavingsAmount = fixed.value }
        }
        return entry
    }

    /// Builds the store a scenario declares, before any plan is applied.
    static func buildDocument(_ payload: GoldenScenarioPayload) -> StoreDocument {
        var document = StoreDocument.seeded()
        document.profile = ProfileRecord(
            name: "Golden",
            currencyCode: "RON",
            remainingMoneyDestination: payload.remainingMoneyDestination ?? .primarySavings
        )
        document.income = IncomeRecord(amount: payload.monthlyIncome.value)
        document.savings = SavingsRecord(allocation(from: payload.savings))

        document.accounts = payload.accounts.enumerated().map { index, account in
            AccountRecord(
                id: uuid(for: account.id),
                name: account.name,
                accountType: account.type,
                isPrimary: account.type == .primary,
                // Default a savings account to primary-savings, matching the app's own factory.
                isPrimarySavings: account.isPrimarySavings ?? (account.type == .savings),
                emergencyMultiplier: account.emergencyMultiplier,
                emergencyHardCap: account.emergencyHardCap?.value,
                currentBalance: account.currentBalance?.value ?? 0,
                sortOrder: index
            )
        }

        let primaryKey = payload.accounts.first { $0.type == .primary }?.id
        document.expenses = payload.expenses.enumerated().map { index, expense in
            // `nil` linkedAccountId means primary, so a fixture pointing at the primary key is
            // normalised to nil — that is how the app stores it.
            let linked: UUID? = {
                guard let key = expense.linkedAccountId, key != primaryKey else { return nil }
                return uuid(for: key)
            }()
            return ExpenseRecord(
                name: expense.name,
                amount: expense.amount.value,
                frequency: expense.frequency ?? .monthly,
                icon: Defaults.expenseIcon,
                isEnabled: expense.isEnabled ?? true,
                linkedAccountId: linked,
                categoryId: expense.categoryId.map { categoryId(for: $0) },
                sortOrder: index
            )
        }

        return document
    }

    /// `phase`, with the all-zero-balances fallback for a scenario that omits it.
    static func phase(of payload: GoldenScenarioPayload) -> String {
        payload.phase ?? (
            payload.accounts.allSatisfy { ($0.currentBalance?.value ?? 0) == 0 }
                ? "onboarding" : "established"
        )
    }

    /// Replays a base scenario to the state its own `phase` implies, so a chained vector starts
    /// from real post-month-1 balances rather than its declared ones. Recurses for a deeper chain.
    static func replayBase(_ base: GoldenScenarioPayload) -> StoreDocument {
        var document: StoreDocument
        if let deeper = base.base {
            document = replayBase(deeper)
            document = overlay(base, onto: document)
        } else {
            document = buildDocument(base)
        }

        if let newMonth = base.newMonth {
            var reconciled: [String: DecimalString] = [:]
            for (key, value) in newMonth.accountBalancesEnteredByUser ?? [:] {
                reconciled[uuid(for: key).uuidString] = value
            }
            NewMonthService.commit(
                NewMonthPayload(income: newMonth.income, reconciledBalances: reconciled),
                to: &document
            )
        } else if phase(of: base) == "onboarding" {
            applyPlan(to: &document)
        }
        return document
    }

    /// A chained child usually declares only `newMonth` (plus any `extraAccounts`), so whatever it
    /// *does* declare is layered over the replayed base instead of replacing it.
    static func overlay(
        _ payload: GoldenScenarioPayload,
        onto base: StoreDocument
    ) -> StoreDocument {
        var document = base
        if payload.monthlyIncome.value > 0 {
            document.income = IncomeRecord(amount: payload.monthlyIncome.value)
        }
        if payload.savings != nil {
            document.savings = SavingsRecord(allocation(from: payload.savings))
        }
        if let destination = payload.remainingMoneyDestination {
            document.profile?.remainingMoneyDestination = destination
        }
        // Accounts the child adds that the base did not have — S16's Joint account.
        for account in payload.accounts {
            let id = uuid(for: account.id)
            guard !document.accounts.contains(where: { $0.id == id }) else { continue }
            document.accounts.append(
                AccountRecord(
                    id: id,
                    name: account.name,
                    accountType: account.type,
                    isPrimary: account.type == .primary,
                    isPrimarySavings: account.isPrimarySavings ?? (account.type == .savings),
                    emergencyMultiplier: account.emergencyMultiplier,
                    emergencyHardCap: account.emergencyHardCap?.value,
                    currentBalance: account.currentBalance?.value ?? 0,
                    sortOrder: document.accounts.count
                )
            )
        }
        return document
    }

    public static func evaluate(
        _ payload: GoldenScenarioPayload,
        assembler: StateAssembler
    ) -> GoldenResultResponse {
        // Chained vector: replay the base for real, then layer this scenario's own declarations.
        var document = payload.base
            .map { overlay(payload, onto: replayBase($0)) }
            ?? buildDocument(payload)

        var unallocated: Decimal = 0
        // For a chained scenario, the plan the user actually saw on New Month step 3. Re-deriving
        // it after the commit would describe the *following* month (4%→8% becomes 8%→13%).
        var atStepPlan: TransferPlanDTO?

        // A scenario describes two moments at once: the plan the user reviewed (S01's
        // `emergencyProgressBefore: 0`, computed while the fund is still empty) and the dashboard
        // afterwards (S01's `emergencyProgressAmounts: "1,182 RON / 27,000 RON"`, post-transfer).
        // So capture the plan first, then apply it, and read balances from the applied state.
        // Balances as declared, before any plan is applied — needed to report what an account
        // *received* this month rather than what it holds.
        var balancesBefore: [UUID: Decimal] = [:]
        for record in document.accounts {
            balancesBefore[record.id] = record.currentBalance.value
        }
        // What each account *receives* from the plan this month. Always plan-derived via
        // `BalanceReconciler`, never a stored-balance delta: an `established` scenario does not
        // apply its plan, so the balance never moves even though the screen shows a transfer
        // (S13's savings spill of 1,082.5 against a stored balance of 0).
        var received: [UUID: Decimal] = [:]

        if payload.newMonth == nil {
            atStepPlan = assembler.assemble(document).transferPlan
            // `phase` decides whether the plan is applied. An "onboarding" scenario describes the
            // dashboard right after the first transfers (S01's ring reads "1,182 / 27,000"); an
            // "established" one describes pre-existing state to be read as-is (S05's fund sits at
            // 26,999 showing 99%, which topping it up to 27,000 would destroy).
            let entries = document.accounts.map { $0.toEntry() }
            let reconciliation = BalanceReconciler.reconcile(
                plan: domainPlan(for: document),
                accounts: entries,
                reconciledBalances: balancesBefore
            )
            for (id, after) in reconciliation.balances {
                received[id] = after - (balancesBefore[id] ?? 0)
            }

            if phase(of: payload) == "onboarding" {
                applyPlan(to: &document)
            }
        }

        // Chained scenarios pass the post-month-1 balances explicitly in
        // `accountBalancesEnteredByUser`, so month 1 needs no replay.
        if let newMonth = payload.newMonth {
            var reconciled: [String: DecimalString] = [:]
            for (key, value) in newMonth.accountBalancesEnteredByUser ?? [:] {
                reconciled[uuid(for: key).uuidString] = value
            }
            let monthPayload = NewMonthPayload(income: newMonth.income, reconciledBalances: reconciled)
            // The reconcile step's values are the real "before" for this month — the scenario's
            // declared balances describe the month *prior*.
            for (key, value) in newMonth.accountBalancesEnteredByUser ?? [:] {
                balancesBefore[uuid(for: key)] = value.value
            }
            let preview = NewMonthService.preview(
                monthPayload, document: document, assembler: assembler
            )
            // `projectedBalances` already carries before/after per account, straight from
            // `BalanceReconciler`.
            for projected in preview.projectedBalances {
                let before = balancesBefore[projected.accountId] ?? projected.before.amount.value
                received[projected.accountId] = projected.after.amount.value - before
            }
            unallocated = preview.unallocatedRemainingMoney?.amount.value ?? 0
            atStepPlan = preview.transferPlan
            NewMonthService.commit(monthPayload, to: &document)
        }

        return result(
            document: document,
            unallocated: unallocated,
            accountKeys: payload.accounts.map(\.id),
            atStepPlan: atStepPlan,
            received: received,
            assembler: assembler
        )
    }

    /// The plan for a document's current state, built exactly as the assembler does.
    private static func domainPlan(for document: StoreDocument) -> TransferPlan {
        let expenses = document.expenses
            .filter(\.isEnabled)
            .map { record in
                ExpenseEntry(
                    name: record.name,
                    amount: record.toEntry().monthlyAmount,
                    icon: record.icon,
                    linkedAccountId: record.linkedAccountId
                )
            }
        return TransferCalculator.calculate(
            income: document.monthlyIncome,
            expenses: expenses,
            allocation: document.savings.toEntry(),
            accounts: document.accounts.map { $0.toEntry() },
            remainingDestination: document.profile?.remainingMoneyDestination ?? .primarySavings
        )
    }

    /// Applies the current plan to balances, exactly as onboarding's save does — via
    /// `Domain.BalanceReconciler`, so no balance arithmetic happens here.
    private static func applyPlan(to document: inout StoreDocument) {
        let entries = document.accounts.map { $0.toEntry() }
        let expenses = document.expenses
            .filter(\.isEnabled)
            .map { record in
                ExpenseEntry(
                    name: record.name,
                    amount: record.toEntry().monthlyAmount,
                    icon: record.icon,
                    linkedAccountId: record.linkedAccountId
                )
            }
        let plan = TransferCalculator.calculate(
            income: document.monthlyIncome,
            expenses: expenses,
            allocation: document.savings.toEntry(),
            accounts: entries,
            remainingDestination: document.profile?.remainingMoneyDestination ?? .primarySavings
        )
        let reconciliation = BalanceReconciler.reconcile(
            plan: plan, accounts: entries, reconciledBalances: [:]
        )
        for index in document.accounts.indices {
            if let balance = reconciliation.balances[document.accounts[index].id] {
                document.accounts[index].currentBalance = DecimalString(balance)
            }
        }
    }

    private static func result(
        document: StoreDocument,
        unallocated: Decimal,
        accountKeys: [String],
        atStepPlan: TransferPlanDTO? = nil,
        received: [UUID: Decimal] = [:],
        assembler: StateAssembler
    ) -> GoldenResultResponse {
        let state = assembler.assemble(document)
        // Post-commit state for balances; the at-step plan (when there was one) for the
        // allocation/progress figures the screen displayed.
        let plan = atStepPlan ?? state.transferPlan
        let money = MoneyFormatter(currency: document.currency)

        // `.first` for the progress fields (only one emergency row can carry them), but amounts
        // are summed: in Split-at-target the same savings account appears twice (R25 row 8).
        let emergency = plan.accountAllocations.first { $0.accountType == "emergency" }
        let savings = plan.accountAllocations.first { $0.accountType == "savings" }
        func allocationTotal(_ type: String) -> Decimal {
            plan.accountAllocations
                .filter { $0.accountType == type }
                .reduce(Decimal(0)) { $0 + $1.amount.amount.value }
        }
        let split = state.settings.savings.split

        func balance(_ type: AccountType) -> AccountDTO? {
            state.accounts.first { $0.accountType == type.rawValue }
        }

        var raw: [String: String] = [
            "monthlyIncome": plan.income.amount.text,
            "dashboardTotalExpensesRaw": state.dashboard.summary.expenses.amount.text,
            "expensesTabTotalMonthlyNormalised": state.expensesScreen.totalMonthly.amount.text,
            "availableIncome": plan.availableIncome.amount.text,
            "savingsAmount": plan.totalSavings.amount.text,
            "personalSpending": plan.remainingMoney.amount.text,
            "emergencyAllocation": DecimalString(allocationTotal("emergency")).text,
            "savingsAllocation": DecimalString(allocationTotal("savings")).text,
            "staysInPrimary": plan.remainsInPrimary.amount.text,
            "splitTotalMonthly": split.requestedTotal.amount.text,
            "unallocatedRemaining": DecimalString(unallocated).text
        ]
        var display: [String: String] = [
            "monthlyIncome": plan.income.display,
            "dashboardTotalExpensesRaw": state.dashboard.summary.expenses.display,
            "expensesTabTotalMonthlyNormalised": state.expensesScreen.totalMonthly.display,
            "availableIncome": plan.availableIncome.display,
            "savingsAmount": plan.totalSavings.display,
            "personalSpending": plan.remainingMoney.display,
            "emergencyAllocation": emergency?.amount.display ?? money(0).display,
            "savingsAllocation": savings?.amount.display ?? money(0).display,
            "staysInPrimary": plan.remainsInPrimary.display,
            "splitTotalMonthly": split.requestedTotal.display,
            "dashboardTotalExpensesRawNegative":
                negatedDisplay(state.dashboard.summary.expenses)
        ]
        var percent: [String: Int] = [:]
        let flags: [String: Bool] = [
            "isBalanced": plan.isBalanced,
            "splitWasScaledDown": split.wasScaledDown
        ]

        if let emergencyAccount = balance(.emergency) {
            // Post-transfer balance (S09): the allocation's own `currentBalance + amount`, which is
            // the `newBalance` Domain computes inside `calculateEmergencyAllocation` but doesn't
            // expose. Reported even for an `established` phase, where the plan is not applied.
            let after = emergency.map { $0.currentBalance.amount.value + $0.amount.amount.value }
                ?? emergencyAccount.currentBalance.amount.value
            raw["emergencyBalanceAfter"] = DecimalString(after).text
            display["emergencyBalanceAfter"] = money(after).display
            if let uncapped = emergencyAccount.emergencyTargetUncapped {
                raw["emergencyTargetUncapped"] = uncapped.amount.text
                display["emergencyTargetUncapped"] = uncapped.display
            }
            if let cap = emergencyAccount.emergencyHardCap {
                raw["emergencyHardCap"] = cap.amount.text
                display["emergencyHardCap"] = cap.display
            }
        }

        if let fund = state.dashboard.emergencyFund {
            raw["emergencyTarget"] = fund.target.amount.text
            raw["emergencyBalance"] = fund.balance.amount.text
            display["emergencyTarget"] = fund.target.display
            display["emergencyBalance"] = fund.balance.display
            display["emergencyProgressAmounts"] = "\(fund.balance.display) / \(fund.target.display)"
            // Register row 4 — the cap branch, only observable with a hard-capped fund.
            display["targetCaption"] = fund.targetCaption
            percent["emergencyProgress"] = fund.progressPercent
        }
        if let emergency {
            percent["emergencyProgressBefore"] = emergency.progressBeforePercent ?? 0
            percent["emergencyProgressAfter"] = emergency.progressAfterPercent ?? 0
            display["emergencyTransfer"] = signedDisplay(emergency.amount)
        } else if let account = balance(.emergency), let progress = account.emergencyProgressPercent {
            // Split-at-target: the whole share overflows, so Domain emits no emergency row at all.
            // Progress is then simply the account's own, unchanged by this month.
            percent["emergencyProgressBefore"] = progress
            percent["emergencyProgressAfter"] = progress
        }
        if let savings {
            display["savingsTransfer"] = signedDisplay(savings.amount)
        } else if plan.remainingMoney.amount.value > 0 {
            // The New Month screen labels the *remainder* as a savings transfer when the
            // destination is primarySavings. That's a display label only — `savingsAllocation`
            // stays 0, because the plan made no savings allocation.
            display["savingsTransfer"] = signedDisplay(plan.remainingMoney)
        }
        // Settings renders the savings rate as `25%`.
        raw["savingsPercentage"] = String(truncatedPercent(state.settings.savings.percentage))
        // S23: the Savings skip resets to priority/percentage.
        raw["savingsStrategy"] = state.settings.savings.allocationMode
        raw["savingsMode"] = state.settings.savings.savingsInputMode

        if let savingsAccount = balance(.savings) {
            raw["savingsBalance"] = savingsAccount.currentBalance.amount.text
            display["savingsBalance"] = savingsAccount.currentBalance.display
            // What the account received this month — its allocation plus any routed
            // `remainingMoney`. Comes from `BalanceReconciler`, so the routing rule lives in
            // Domain and is not restated here.
            let delta = received[savingsAccount.id] ?? 0
            raw["savingsReceived"] = DecimalString(delta).text
            display["savingsReceived"] = money(delta).display
        }
        // Keyed by the fixture's own account key too, since a scenario may name an account
        // "joint" while typing it `.personal` (S16).
        for key in accountKeys {
            let id = uuid(for: key)
            if let account = state.accounts.first(where: { $0.id == id }) {
                raw["\(key)Balance"] = account.currentBalance.amount.text
                display["\(key)Balance"] = account.currentBalance.display
            }
        }
        if let joint = balance(.joint) {
            raw["jointBalance"] = joint.currentBalance.amount.text
            display["jointBalance"] = joint.currentBalance.display
        }
        if let personal = balance(.personal) {
            raw["personalBalance"] = personal.currentBalance.amount.text
        }
        if let primary = balance(.primary) {
            raw["primaryBalance"] = primary.currentBalance.amount.text
        }

        // The Expenses tab's "1/2 enabled" counter, keyed by category slug.
        for group in state.expensesScreen.categories {
            // `group.name` covers the uncategorized / dangling-category cases too.
            let slug = group.name
                .lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .joined()
            display["\(slug)CategoryCounter"] = group.enabledCaption
        }

        var breakdown: [String: Int] = [:]
        for row in state.dashboard.expenseBreakdown {
            breakdown[row.name.lowercased()] = row.percent
        }
        for (key, value) in breakdown {
            percent["breakdown.\(key)"] = value
        }

        return GoldenResultResponse(
            raw: raw,
            display: display,
            percent: percent,
            flags: flags,
            accountIds: Dictionary(
                uniqueKeysWithValues: accountKeys.map { ($0, uuid(for: $0).uuidString) }
            )
        )
    }
}

public struct CategoryUpdatePayload: Content, Sendable {
    public var name: String?
    public var icon: String?
    public var colorHex: String?
    public var sortOrder: Int?
}
