import Domain
import Foundation
import Testing
import Utilities

@testable import DiamerisServerCore

/// Asserts `Web/Docs/GROUND-TRUTH.md` — the numbers observed by driving the live iOS app.
///
/// These expectations are **the contract, not a description of the code**. If one fails, the
/// server is wrong (or the ground truth was mis-observed and needs re-checking against the
/// simulator). Do not relax an expectation to make a test green.
@Suite("Ground truth — observed iOS values")
struct GroundTruthTests {

    // Test data from GROUND-TRUTH.md: name Vlad, income 9000 RON, Food 1200 / Rent 2500 /
    // Gas 450 / Streaming 120, savings 25% Priority+Percentage, accounts Main + Emergency + Savings.

    static let mainId = UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!
    static let emergencyId = UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000002")!
    static let savingsId = UUID(uuidString: "CCCCCCCC-0000-0000-0000-000000000003")!

    /// The exact payload the onboarding flow would POST for the ground-truth scenario.
    static func onboardingPayload() -> OnboardingPayload {
        OnboardingPayload(
            name: "Vlad",
            currencyCode: "RON",
            monthlyIncome: DecimalString(9000),
            accounts: [
                .init(
                    id: mainId, name: "Main Account", purpose: "Where your salary lands",
                    accountType: .primary, isPrimary: true, isPrimarySavings: false,
                    emergencyMultiplier: nil, emergencyHardCap: nil, currentBalance: DecimalString(0)
                ),
                .init(
                    id: emergencyId, name: "Emergency Fund",
                    purpose: "Protects you from unexpected expenses",
                    accountType: .emergency, isPrimary: false, isPrimarySavings: false,
                    emergencyMultiplier: 3.0, emergencyHardCap: nil, currentBalance: DecimalString(0)
                ),
                .init(
                    id: savingsId, name: "Savings", purpose: "For building wealth over time",
                    accountType: .savings, isPrimary: false, isPrimarySavings: true,
                    emergencyMultiplier: nil, emergencyHardCap: nil, currentBalance: DecimalString(0)
                )
            ],
            expenses: [
                .init(name: "Food", amount: DecimalString(1200), icon: "cart.fill",
                      categoryId: Domain.Category.foodGroceries.id),
                .init(name: "Rent", amount: DecimalString(2500), icon: "house.fill",
                      categoryId: Domain.Category.housing.id),
                .init(name: "Gas", amount: DecimalString(450), icon: "fuelpump.fill",
                      categoryId: Domain.Category.autoTransport.id),
                .init(name: "Streaming", amount: DecimalString(120), icon: "tv.fill",
                      categoryId: Domain.Category.subscriptions.id)
            ],
            savings: SavingsPayload(percentage: 0.25, allocationMode: .prioritized,
                                    savingsInputMode: .percentage),
            remainingMoneyDestination: .primarySavings
        )
    }

    static func onboardedState() -> AppStateResponse {
        var document = StoreDocument.seeded()
        OnboardingService.apply(onboardingPayload(), to: &document)
        return StateAssembler().assemble(document)
    }

    static func onboardedDocument() -> StoreDocument {
        var document = StoreDocument.seeded()
        OnboardingService.apply(onboardingPayload(), to: &document)
        return document
    }

    // MARK: - Month 1

    @Test("Income is 9,000 RON")
    func income() {
        let state = Self.onboardedState()
        #expect(state.settings.income.amount.text == "9000")
        #expect(state.settings.income.display == "9,000 RON")
        #expect(state.dashboard.summary.income.display == "9,000 RON")
    }

    @Test("Monthly expenses are 4,270 RON (1200+2500+450+120)")
    func totalExpenses() {
        let state = Self.onboardedState()
        #expect(state.dashboard.summary.expenses.amount.text == "4270")
        #expect(state.dashboard.summary.expenses.display == "4,270 RON")
        #expect(state.expensesScreen.totalMonthly.display == "4,270 RON")
    }

    @Test("Available income after expenses is 4,730 RON (9000 − 4270)")
    func availableIncome() {
        let state = Self.onboardedState()
        #expect(state.transferPlan.availableIncome.amount.text == "4730")
        #expect(state.transferPlan.availableIncome.display == "4,730 RON")
    }

    /// The single most important assertion in this suite: `1182.5` must be *stored* exactly and
    /// *displayed* as `"1,182 RON"` — half-even rounding of a .5 down to the even integer.
    @Test("Savings @ 25% is 1182.5 stored, displays as 1,182 RON")
    func savings() {
        let state = Self.onboardedState()
        #expect(state.transferPlan.totalSavings.amount.text == "1182.5")
        #expect(state.transferPlan.totalSavings.display == "1,182 RON")
        #expect(state.dashboard.summary.savings.amount.text == "1182.5")
        #expect(state.dashboard.summary.savings.display == "1,182 RON")
    }

    /// The companion case: `3547.5` rounds *up* to `3548`, because 3548 is the even neighbour.
    /// A naive `round()` would give 1183 and 3548 — the pair is what proves half-even.
    @Test("Personal spending is 3547.5 stored, displays as 3,548 RON")
    func personalSpending() {
        let state = Self.onboardedState()
        #expect(state.transferPlan.remainingMoney.amount.text == "3547.5")
        #expect(state.transferPlan.remainingMoney.display == "3,548 RON")
        #expect(state.dashboard.summary.personalSpending.amount.text == "3547.5")
        #expect(state.dashboard.summary.personalSpending.display == "3,548 RON")
    }

    @Test("Emergency target is 27,000 RON (3 × 9,000)")
    func emergencyTarget() {
        let state = Self.onboardedState()
        let fund = try! #require(state.dashboard.emergencyFund)
        #expect(fund.target.amount.text == "27000")
        #expect(fund.target.display == "27,000 RON")
        #expect(fund.targetCaption == "Target: 3× monthly income")
    }

    @Test("Emergency progress after 1 month is 4% (1182.5 / 27000)")
    func emergencyProgressMonth1() {
        let state = Self.onboardedState()
        let fund = try! #require(state.dashboard.emergencyFund)
        #expect(fund.balance.amount.text == "1182.5")
        #expect(fund.balance.display == "1,182 RON")
        #expect(fund.progressPercent == 4)
        #expect(fund.progressDisplay == "4%")
        #expect(fund.isComplete == false)
    }

    /// `0% → 4%` is what **onboarding step 7** shows: the plan computed while the emergency
    /// balance is still zero, before anything is saved.
    @Test("Onboarding step 7 shows emergency 1,182 RON with 0% → 4%")
    func onboardingStep7Allocation() {
        let preview = OnboardingService.preview(Self.onboardingPayload(), assembler: StateAssembler())
        #expect(preview.transferPlan.accountAllocations.count == 1)
        let allocation = try! #require(preview.transferPlan.accountAllocations.first)
        #expect(allocation.accountType == "emergency")
        #expect(allocation.amount.amount.text == "1182.5")
        #expect(allocation.amount.display == "1,182 RON")
        #expect(allocation.progressBeforePercent == 0)
        #expect(allocation.progressAfterPercent == 4)
        #expect(allocation.progressChangeDisplay == "0% → 4%")
        #expect(allocation.targetAmount?.display == "27,000 RON")
        #expect(allocation.isComplete == false)
    }

    /// After onboarding saves, the Dashboard's plan is derived from the *stored* balances, where
    /// the emergency fund already holds 1,182.5. So the same plan now reads `4% → 8%` — that is
    /// the next month's projection, not a regression. The Dashboard card itself shows the
    /// current 4% (asserted in `emergencyProgressMonth1`), which is what GROUND-TRUTH records.
    @Test("Post-onboarding dashboard plan projects the next month as 4% → 8%")
    func dashboardPlanAfterOnboarding() {
        let state = Self.onboardedState()
        #expect(state.transferPlan.accountAllocations.count == 1)
        let allocation = try! #require(state.transferPlan.accountAllocations.first)
        #expect(allocation.amount.amount.text == "1182.5")
        #expect(allocation.progressBeforePercent == 4)
        #expect(allocation.progressAfterPercent == 8)
        #expect(allocation.progressChangeDisplay == "4% → 8%")
    }

    @Test("Month 1: 4,270 RON stays in primary and the plan balances")
    func month1Primary() {
        let state = Self.onboardedState()
        #expect(state.transferPlan.remainsInPrimary.amount.text == "4270")
        #expect(state.transferPlan.remainsInPrimary.display == "4,270 RON")
        #expect(state.transferPlan.isBalanced == true)
        // All four expenses are paid from primary, so there are no cross-account transfers.
        #expect(state.transferPlan.accountExpenseTransfers.isEmpty)
    }

    @Test("Month 1 balances persist as Main 4,270 / Emergency 1,182.5 / Savings 3,547.5")
    func month1Balances() {
        let state = Self.onboardedState()
        func balance(_ id: UUID) -> String {
            state.accounts.first { $0.id == id }!.currentBalance.amount.text
        }
        #expect(balance(Self.mainId) == "4270")
        #expect(balance(Self.emergencyId) == "1182.5")
        #expect(balance(Self.savingsId) == "3547.5")
    }

    // MARK: - Month 2

    /// Runs a second month at the same income, with the balances left by month 1.
    static func afterSecondMonth() -> AppStateResponse {
        var document = onboardedDocument()
        let payload = NewMonthPayload(income: DecimalString(9000), reconciledBalances: nil)
        NewMonthService.commit(payload, to: &document)
        return StateAssembler().assemble(document)
    }

    @Test("Emergency balance after 2 months is 2,365 RON and progress is 8%")
    func month2Emergency() {
        let state = Self.afterSecondMonth()
        let fund = try! #require(state.dashboard.emergencyFund)
        #expect(fund.balance.amount.text == "2365")
        #expect(fund.balance.display == "2,365 RON")
        #expect(fund.progressPercent == 8)
        #expect(fund.progressDisplay == "8%")
    }

    @Test("Savings balance after 2 months is 7,095 RON (3547.5 × 2)")
    func month2Savings() {
        let state = Self.afterSecondMonth()
        let savings = try! #require(state.accounts.first { $0.id == Self.savingsId })
        #expect(savings.currentBalance.amount.text == "7095")
        #expect(savings.currentBalance.display == "7,095 RON")
    }

    @Test("Month 2 preview shows the 4% → 8% transition before committing")
    func month2Preview() {
        let document = Self.onboardedDocument()
        let payload = NewMonthPayload(income: DecimalString(9000), reconciledBalances: nil)
        let preview = NewMonthService.preview(payload, document: document, assembler: StateAssembler())

        let allocation = try! #require(preview.transferPlan.accountAllocations.first)
        #expect(allocation.progressChangeDisplay == "4% → 8%")

        let emergency = try! #require(preview.projectedBalances.first { $0.accountId == Self.emergencyId })
        #expect(emergency.before.display == "1,182 RON")
        #expect(emergency.after.display == "2,365 RON")

        let savings = try! #require(preview.projectedBalances.first { $0.accountId == Self.savingsId })
        #expect(savings.before.display == "3,548 RON")
        #expect(savings.after.display == "7,095 RON")

        // Preview must not have written anything.
        #expect(document.accounts.first { $0.id == Self.emergencyId }!.currentBalance.text == "1182.5")
    }

    @Test("Committing a month does not change what stays in primary")
    func month2Primary() {
        let state = Self.afterSecondMonth()
        let main = try! #require(state.accounts.first { $0.id == Self.mainId })
        #expect(main.currentBalance.amount.text == "4270")
    }

    // MARK: - Expense breakdown

    /// `Int((amount / total) * 100)` — truncating. Streaming's 2.81% becomes `2`, not `3`.
    @Test("Expense breakdown is descending with truncated percentages")
    func expenseBreakdown() {
        let state = Self.onboardedState()
        let rows = state.dashboard.expenseBreakdown
        #expect(rows.count == 4)
        #expect(rows.map(\.name) == ["Rent", "Food", "Gas", "Streaming"])
        #expect(rows.map(\.percent) == [58, 28, 10, 2])
        #expect(rows.map(\.amount.display) == ["2,500 RON", "1,200 RON", "450 RON", "120 RON"])
    }

    // MARK: - Onboarding preview

    @Test("Onboarding preview matches the live values shown on steps 5 and 6")
    func onboardingPreview() {
        let preview = OnboardingService.preview(Self.onboardingPayload(), assembler: StateAssembler())
        // Step 5's "After expenses / 4,730 RON / available for your goals"
        #expect(preview.availableIncome.display == "4,730 RON")
        // Step 6's "That's 1,182 RON/month"
        #expect(preview.savingsAmount.amount.text == "1182.5")
        #expect(preview.savingsAmount.display == "1,182 RON")
        #expect(preview.totalExpenses.display == "4,270 RON")
        // Step 7's transfer plan
        #expect(preview.transferPlan.remainingMoney.display == "3,548 RON")
    }
}

// MARK: - Money encoding

@Suite("Money never becomes a float")
struct MoneyEncodingTests {

    @Test("1182.5 round-trips exactly through JSON as a string")
    func roundTrip() throws {
        let original = DecimalString(Decimal(string: "1182.5")!)
        let data = try JSONEncoder().encode(original)

        // The wire form must be a quoted string. A bare 1182.5 would be a JSON number, and the
        // moment JavaScript parses that we are at the mercy of binary floating point.
        #expect(String(decoding: data, as: UTF8.self) == "\"1182.5\"")

        let decoded = try JSONDecoder().decode(DecimalString.self, from: data)
        #expect(decoded.value == original.value)
        #expect(decoded.text == "1182.5")
    }

    @Test("A JSON number is rejected rather than silently accepted")
    func rejectsNumbers() {
        let json = Data("1182.5".utf8)
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(DecimalString.self, from: json)
        }
    }

    @Test("Decimal strings parse locale-independently")
    func localeIndependent() throws {
        #expect(DecimalString.parse("1182.5") == Decimal(string: "1182.5"))
        #expect(DecimalString.parse("0") == 0)
        #expect(DecimalString.parse("") == nil)
        #expect(DecimalString.parse("abc") == nil)
    }

    @Test("Zero encodes as \"0\", never \"-0\"")
    func zero() {
        #expect(DecimalString(Decimal(0)).text == "0")
        #expect(DecimalString(Decimal(0) * -1).text == "0")
    }

    /// The half-even pair. `1182.5 → 1182` (down to even) and `3547.5 → 3548` (up to even).
    /// `Math.round` in JS would give 1183 and 3548, so this pair is the parity canary.
    @Test("Display formatting is half-even, matching NumberFormatter's default", arguments: [
        ("1182.5", "1,182 RON"),
        ("3547.5", "3,548 RON"),
        ("2365", "2,365 RON"),
        ("7095", "7,095 RON"),
        ("27000", "27,000 RON"),
        ("14303", "14,303 RON"),
        ("0", "0 RON")
    ])
    func halfEven(input: String, expected: String) {
        let money = Money(Decimal(string: input)!, currency: "RON")
        #expect(money.display == expected)
    }

    /// `formatForEditing` returns `""` for non-positive amounts — which is why an amount field
    /// showing a zero balance is blank rather than showing "0".
    @Test("editing is empty for non-positive amounts, matching formatForEditing")
    func editingEmptyForNonPositive() {
        #expect(Money(0, currency: "RON").editing == "")
        #expect(Money(Decimal(string: "-5")!, currency: "RON").editing == "")
    }

    /// ⚠️ `formatForEditing` forces `groupingSeparator = ""` but leaves the **decimal** separator
    /// to the host locale, so `1182.5` becomes `"1182,5"` on a comma-locale machine and
    /// `"1182.5"` on a period-locale one. This is faithful — `GROUND-TRUTH.md` records the iOS
    /// New Month fields prefilled as `3547,5` and `1182,5`, i.e. the reference device was on a
    /// comma locale. Asserted against the live locale rather than a hardcoded separator, because
    /// pinning either one would be a lie on the other machine.
    ///
    /// Consequence for the client: `editing` is display-only. Round-trip the canonical
    /// `amount` (or `POST /api/parse-amount`) — never parse `editing` yourself.
    @Test("editing uses the host locale's decimal separator, as iOS does")
    func editingUsesLocaleSeparator() {
        let separator = Locale.current.decimalSeparator ?? "."
        #expect(Money(Decimal(string: "1182.5")!, currency: "RON").editing == "1182\(separator)5")
        #expect(Money(Decimal(string: "3547.5")!, currency: "RON").editing == "3547\(separator)5")
        // No grouping, ever — that is forced, not locale-dependent.
        #expect(Money(Decimal(string: "27000")!, currency: "RON").editing == "27000")
    }

    /// The `amount` field, by contrast, is locale-independent — it must be, because it is the
    /// value the client sends back.
    @Test("amount is canonical regardless of locale")
    func amountIsCanonical() {
        #expect(Money(Decimal(string: "1182.5")!, currency: "RON").amount.text == "1182.5")
        #expect(Money(Decimal(string: "3547.5")!, currency: "RON").amount.text == "3547.5")
    }

    @Test("Percentages truncate, they do not round")
    func percentTruncation() {
        #expect(truncatedPercent(0.0438) == 4)
        #expect(truncatedPercent(0.0876) == 8)
        #expect(truncatedPercent(0.259) == 25)
        #expect(truncatedPercent(0.999) == 99)
    }
}

// MARK: - Store

@Suite("JSON store")
struct JSONStoreTests {

    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("diameris-tests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("web-store.json")
    }

    @Test("First launch seeds the 8 default categories from Domain and nothing else")
    func seed() async throws {
        let store = JSONStore(fileURL: temporaryURL())
        let document = try await store.load()

        #expect(document.schemaVersion == 1)
        #expect(document.categories.count == 8)
        #expect(document.categories.map(\.name) == Domain.Category.defaults.map(\.name))
        #expect(document.categories.map(\.id) == Domain.Category.defaults.map(\.id))
        #expect(document.categories.map(\.colorHex) == Domain.Category.defaults.map(\.colorHex))
        #expect(document.categories.allSatisfy { $0.isDefault })

        // Accounts and expenses come from onboarding, not the seed.
        #expect(document.accounts.isEmpty)
        #expect(document.expenses.isEmpty)
        #expect(document.profile == nil)
        #expect(document.income == nil)
        #expect(document.onboardingCompleted == false)

        // Default savings settings are Domain's, not transcribed.
        let entry = document.savings.toEntry()
        let domainDefaults = SavingsAllocationEntry()
        #expect(entry.percentage == domainDefaults.percentage)
        #expect(entry.allocationMode == domainDefaults.allocationMode)
        #expect(entry.savingsInputMode == domainDefaults.savingsInputMode)
        #expect(entry.splitEmergencyInputMode == domainDefaults.splitEmergencyInputMode)
        #expect(entry.splitEmergencyPercentage == domainDefaults.splitEmergencyPercentage)
        #expect(entry.splitSavingsPercentage == domainDefaults.splitSavingsPercentage)
    }

    @Test("The seeded category ids are the exact fixed UUIDs from DOMAIN-CONTRACT §6")
    func categoryUUIDs() async throws {
        let store = JSONStore(fileURL: temporaryURL())
        let document = try await store.load()
        let expected = [
            "D1A00001-0000-0000-0000-000000000001",
            "D1A00002-0000-0000-0000-000000000002",
            "D1A00003-0000-0000-0000-000000000003",
            "D1A00004-0000-0000-0000-000000000004",
            "D1A00005-0000-0000-0000-000000000005",
            "D1A00006-0000-0000-0000-000000000006",
            "D1A00007-0000-0000-0000-000000000007",
            "D1A00008-0000-0000-0000-000000000008"
        ]
        #expect(document.categories.map(\.id.uuidString) == expected)
        #expect(document.categories.map(\.icon) == [
            "car.fill", "repeat.circle.fill", "sparkles", "house.fill",
            "pawprint.fill", "heart.fill", "cart.fill", "tv.fill"
        ])
    }

    @Test("1182.5 survives a write, an eviction and a re-read from disk")
    func decimalPersistence() async throws {
        let url = temporaryURL()
        let store = JSONStore(fileURL: url)
        _ = try await store.mutate { document in
            OnboardingService.apply(GroundTruthTests.onboardingPayload(), to: &document)
        }

        // A brand-new actor, so nothing can be served from the in-memory cache.
        let reopened = JSONStore(fileURL: url)
        let document = try await reopened.load()
        let emergency = try #require(
            document.accounts.first { $0.id == GroundTruthTests.emergencyId }
        )
        #expect(emergency.currentBalance.text == "1182.5")

        // And it really is a string on disk, not a number.
        let raw = try String(contentsOf: url, encoding: .utf8)
        #expect(raw.contains("\"1182.5\""))
    }

    @Test("Reset returns the store to a freshly seeded state")
    func reset() async throws {
        let store = JSONStore(fileURL: temporaryURL())
        _ = try await store.mutate { document in
            OnboardingService.apply(GroundTruthTests.onboardingPayload(), to: &document)
        }
        let afterOnboarding = try await store.load()
        #expect(afterOnboarding.onboardingCompleted == true)

        let afterReset = try await store.reset()
        #expect(afterReset.onboardingCompleted == false)
        #expect(afterReset.accounts.isEmpty)
        #expect(afterReset.categories.count == 8)
    }

    @Test("Concurrent mutations all land — the actor serialises read-modify-write")
    func concurrentMutations() async throws {
        let store = JSONStore(fileURL: temporaryURL())
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<25 {
                group.addTask {
                    _ = try? await store.mutate { document in
                        document.expenses.append(
                            ExpenseRecord(name: "e\(index)", amount: 1, icon: "x", sortOrder: index)
                        )
                    }
                }
            }
        }
        let final = try await store.load()
        #expect(final.expenses.count == 25)
    }
}

// MARK: - Determinism and localization

@Suite("Determinism")
struct DeterminismTests {

    @Test("accountExpenseTransfers are sorted by account name, not Dictionary order")
    func transfersSorted() {
        // Three expenses, each paid from a different non-primary account, so Domain builds three
        // transfers by grouping a Dictionary — whose iteration order is unspecified.
        let primary = AccountEntry(name: "Main Account", accountType: .primary, isPrimary: true)
        let zed = AccountEntry(name: "Zed Account", accountType: .other)
        let alpha = AccountEntry(name: "Alpha Account", accountType: .other)
        let mid = AccountEntry(name: "Mid Account", accountType: .joint)

        var document = StoreDocument.seeded()
        document.profile = ProfileRecord(name: "Vlad", currencyCode: "RON")
        document.income = IncomeRecord(amount: 9000)
        document.accounts = [primary, zed, alpha, mid].enumerated()
            .map { AccountRecord($1, sortOrder: $0) }
        document.expenses = [
            ExpenseRecord(name: "Z", amount: 100, icon: "x", linkedAccountId: zed.id, sortOrder: 0),
            ExpenseRecord(name: "A", amount: 200, icon: "x", linkedAccountId: alpha.id, sortOrder: 1),
            ExpenseRecord(name: "M", amount: 300, icon: "x", linkedAccountId: mid.id, sortOrder: 2)
        ]

        // Repeat, because a single pass can pass by luck on a nondeterministic ordering.
        for _ in 0..<20 {
            let state = StateAssembler().assemble(document)
            #expect(
                state.transferPlan.accountExpenseTransfers.map(\.accountName)
                    == ["Alpha Account", "Mid Account", "Zed Account"]
            )
        }
    }

    /// Pins the macOS localization behaviour: SwiftPM copies `Localizable.xcstrings` without
    /// compiling it, so `.localized` falls back to the key — and the keys *are* the English
    /// strings. So EN is exact server-side; RO belongs to the client's i18n dictionary.
    @Test("Domain display names come back as the English strings")
    func englishDisplayNames() {
        #expect(AccountType.primary.displayName == "Primary")
        #expect(AccountType.emergency.displayName == "Emergency")
        #expect(AccountType.savings.displayName == "Savings")
        #expect(AllocationMode.prioritized.displayName == "Priority")
        #expect(AllocationMode.split.displayName == "Split")
        #expect(SavingsInputMode.fixedAmount.displayName == "Fixed Amount")
        #expect(RemainingMoneyDestination.primarySavings.displayName == "Primary Savings")
        #expect(RemainingMoneyDestination.primary.displayName == "Keep in Primary")
    }

    @Test("Reference tables preserve Domain's allCases order")
    func referenceOrder() {
        let reference = StateAssembler().reference()
        #expect(reference.accountTypes.map(\.value)
            == ["primary", "emergency", "savings", "personal", "joint", "other"])
        #expect(reference.frequencies.map(\.value) == ["monthly", "annual"])
        #expect(reference.allocationModes.map(\.value) == ["prioritized", "split"])
        #expect(reference.remainingMoneyDestinations.map(\.value)
            == ["primarySavings", "personal", "primary"])
        #expect(reference.currencies.map(\.value) == ["RON", "EUR", "USD"])
        // 37, per AddExpenseSheet.swift:193-231 — GROUND-TRUTH's "18" came from a clipped
        // screenshot, where `creditcard.fill` (the 18th) was the last visible row (R12).
        #expect(reference.expenseIcons.count == 37)
        #expect(reference.expenseIcons.first == "dollarsign.circle.fill")
        #expect(reference.expenseIcons[17] == "creditcard.fill")
        #expect(reference.expenseIcons.last == "sparkles")
        // A different set from expenseIcons — sharing one array would break a screen.
        #expect(reference.categoryIcons.count == 12)
        #expect(reference.categoryColors.count == 10)
        #expect(reference.categoryIcons.contains("calendar"))
        #expect(!reference.expenseIcons.contains("calendar"))
        #expect(reference.emergencyMultiplierOptions.map(\.multiplier) == [3, 4, 5, 6])
        #expect(reference.emergencyMultiplierOptions.map(\.caption) == [
            "Minimum recommended", "Standard protection", "Enhanced protection", "Maximum security"
        ])
        #expect(reference.emergencyMultiplierOptions.map(\.display) == ["3×", "4×", "5×", "6×"])
        // ⚠️ The "Emergency" chip really does create a .savings account — iOS bug, reproduced.
        #expect(reference.accountSuggestions.map(\.title) == ["Joint", "Emergency", "Travel"])
        #expect(reference.accountSuggestions.map(\.accountType) == ["joint", "savings", "savings"])
        #expect(reference.savingsConstants.minimumPercentage == 0.05)
        #expect(reference.savingsConstants.maximumPercentage == 0.50)
    }

    @Test("A nil linkedAccountId resolves to the primary account's name")
    func linkedAccountName() {
        let state = GroundTruthTests.onboardedState()
        #expect(state.expenses.allSatisfy { $0.linkedAccountId == nil })
        #expect(state.expenses.allSatisfy { $0.linkedAccountName == "Main Account" })
    }

    @Test("Annual expenses are normalised to monthly before the calculator sees them")
    func annualNormalisation() {
        var document = StoreDocument.seeded()
        document.profile = ProfileRecord(name: "Vlad", currencyCode: "RON")
        document.income = IncomeRecord(amount: 9000)
        document.accounts = [
            AccountRecord(
                AccountEntry(name: "Main Account", accountType: .primary, isPrimary: true),
                sortOrder: 0
            )
        ]
        // 1,200/year must count as 100/month, not 1,200/month. `TransferCalculator` sums raw
        // `amount`, so the caller has to normalise — this is that behaviour.
        document.expenses = [
            ExpenseRecord(name: "Insurance", amount: 1200, frequency: .annual, icon: "x")
        ]

        let state = StateAssembler().assemble(document)
        #expect(state.dashboard.summary.expenses.display == "100 RON")
        #expect(state.expensesScreen.totalMonthly.display == "100 RON")
        #expect(state.expensesScreen.totalAnnual.display == "1,200 RON")
    }

    @Test("Disabled expenses are excluded from every total")
    func disabledExpenses() {
        var document = GroundTruthTests.onboardedDocument()
        let rentIndex = document.expenses.firstIndex { $0.name == "Rent" }!
        document.expenses[rentIndex].isEnabled = false

        let state = StateAssembler().assemble(document)
        // 4270 − 2500 = 1770
        #expect(state.dashboard.summary.expenses.display == "1,770 RON")
        #expect(state.dashboard.expenseBreakdown.map(\.name) == ["Food", "Gas", "Streaming"])

        let housing = try! #require(
            state.expensesScreen.categories.first { $0.name == "Housing" }
        )
        #expect(housing.enabledCaption == "0/1 enabled")
        #expect(housing.monthlyTotal.display == "0 RON")
    }

    @Test("The worked example from TransferPlanScreen's preview reproduces exactly")
    func workedExample() {
        // DOMAIN-CONTRACT §3: income 14303, expenses 3000 + 300, 25% prioritized/percentage,
        // emergency ×3.0 with balance 37056, plus a primary-savings account.
        let primary = AccountEntry(name: "Main", accountType: .primary, isPrimary: true)
        let emergency = AccountEntry(
            name: "Emergency", accountType: .emergency,
            emergencyMultiplier: 3.0, currentBalance: 37056
        )
        let savings = AccountEntry(name: "Savings", accountType: .savings, isPrimarySavings: true)

        var document = StoreDocument.seeded()
        document.profile = ProfileRecord(name: "Vlad", currencyCode: "RON")
        document.income = IncomeRecord(amount: 14303)
        document.accounts = [primary, emergency, savings].enumerated()
            .map { AccountRecord($1, sortOrder: $0) }
        document.expenses = [
            ExpenseRecord(name: "Rent", amount: 3000, icon: "x", sortOrder: 0),
            ExpenseRecord(name: "Other", amount: 300, icon: "x", sortOrder: 1)
        ]

        let plan = StateAssembler().assemble(document).transferPlan
        #expect(plan.totalExpenses.amount.text == "3300")
        #expect(plan.availableIncome.amount.text == "11003")
        #expect(plan.totalSavings.amount.text == "2750.75")
        #expect(plan.remainingMoney.amount.text == "8252.25")
        #expect(plan.remainsInPrimary.amount.text == "3300")
        #expect(plan.isBalanced == true)

        let allocation = try! #require(plan.accountAllocations.first)
        #expect(allocation.amount.amount.text == "2750.75")
        #expect(allocation.targetAmount?.amount.text == "42909")
        #expect(allocation.progressChangeDisplay == "86% → 92%")
        #expect(allocation.isComplete == false)
    }
}

// MARK: - Balance reconciliation guards

/// `BalanceReconciler`'s defences against a caller supplying an incomplete picture (R10).
@Suite("Balance reconciliation guards")
struct BalanceReconcilerGuardTests {

    private func plan(
        income: Decimal,
        expenses: [ExpenseEntry],
        accounts: [AccountEntry],
        destination: RemainingMoneyDestination,
        percentage: Double = 0.25
    ) -> TransferPlan {
        TransferCalculator.calculate(
            income: income,
            expenses: expenses,
            allocation: SavingsAllocationEntry(percentage: percentage),
            accounts: accounts,
            remainingDestination: destination
        )
    }

    /// The bug this guards: a Joint account is never part of the New Month reconcile step (it is
    /// not emergency/savings/personal), so it is absent from `reconciledBalances`. Seeding it at
    /// zero would silently wipe its balance the moment an expense transfer touched it.
    @Test("An un-reconciled account keeps its balance instead of restarting at zero")
    func unreconciledAccountKeepsBalance() {
        let primary = AccountEntry(name: "Main", accountType: .primary, isPrimary: true)
        let joint = AccountEntry(name: "Joint", accountType: .joint, currentBalance: 900)
        let accounts = [primary, joint]

        let expenses = [
            ExpenseEntry(name: "Food", amount: 300, icon: "cart.fill", linkedAccountId: joint.id)
        ]
        let transferPlan = plan(
            income: 5000, expenses: expenses, accounts: accounts, destination: .primary
        )

        // Deliberately partial: only the primary is reconciled, exactly as the iOS sheet does.
        let result = BalanceReconciler.reconcile(
            plan: transferPlan,
            accounts: accounts,
            reconciledBalances: [primary.id: 5000]
        )

        // 900 (kept) + 300 (transfer) = 1200. A zero seed would have produced 300.
        #expect(result.balances[joint.id] == 1200)
        #expect(result.unallocatedRemainingMoney == 0)
        #expect(result.unknownAccountIds.isEmpty)
    }

    @Test("A reconciled balance still overrides the stored one")
    func reconciledOverridesStored() {
        let primary = AccountEntry(name: "Main", accountType: .primary, isPrimary: true)
        let savings = AccountEntry(
            name: "Savings", accountType: .savings, isPrimarySavings: true, currentBalance: 5000
        )
        let accounts = [primary, savings]
        let transferPlan = plan(
            income: 1000, expenses: [], accounts: accounts, destination: .primary
        )

        let result = BalanceReconciler.reconcile(
            plan: transferPlan,
            accounts: accounts,
            reconciledBalances: [savings.id: 8000]
        )
        // 8000 (user's correction, not the stored 5000) + 250 allocation
        #expect(result.balances[savings.id] == 8250)
    }

    /// The silent-loss branch: destination names a role nothing fills, so the money lands nowhere.
    @Test("Remaining money with no primary-savings account is surfaced, not dropped")
    func unallocatedPrimarySavings() {
        // No account has isPrimarySavings, and no .savings account either, so the savings pool
        // cannot be placed and the whole remainder has nowhere to go.
        let primary = AccountEntry(name: "Main", accountType: .primary, isPrimary: true)
        let accounts = [primary]
        let transferPlan = plan(
            income: 1000, expenses: [], accounts: accounts, destination: .primarySavings
        )

        let result = BalanceReconciler.reconcile(
            plan: transferPlan, accounts: accounts, reconciledBalances: [:]
        )
        #expect(transferPlan.remainingMoney == 1000)
        #expect(result.unallocatedRemainingMoney == 1000)
    }

    @Test("Remaining money with no personal account is surfaced too")
    func unallocatedPersonal() {
        let primary = AccountEntry(name: "Main", accountType: .primary, isPrimary: true)
        let accounts = [primary]
        let transferPlan = plan(
            income: 1000, expenses: [], accounts: accounts, destination: .personal
        )
        let result = BalanceReconciler.reconcile(
            plan: transferPlan, accounts: accounts, reconciledBalances: [:]
        )
        #expect(result.unallocatedRemainingMoney == 1000)
    }

    /// `.primary` is never "lost" — step 5 assigns `remainsInPrimary` outright, which is the
    /// intended destination.
    @Test("Destination .primary reports nothing unallocated")
    func primaryDestinationNeverUnallocated() {
        let primary = AccountEntry(name: "Main", accountType: .primary, isPrimary: true)
        let accounts = [primary]
        let transferPlan = plan(
            income: 1000, expenses: [], accounts: accounts, destination: .primary
        )
        let result = BalanceReconciler.reconcile(
            plan: transferPlan, accounts: accounts, reconciledBalances: [:]
        )
        #expect(result.unallocatedRemainingMoney == 0)
    }

    /// A dangling `linkedAccountId` — possible because those are loose UUIDs with no FK.
    @Test("An account id the plan references but we were not given is reported")
    func unknownAccountReported() {
        let primary = AccountEntry(name: "Main", accountType: .primary, isPrimary: true)
        let ghostId = UUID()
        let expenses = [
            ExpenseEntry(name: "Food", amount: 300, icon: "cart.fill", linkedAccountId: ghostId)
        ]
        // The plan is built with the ghost visible so a transfer is produced...
        let ghost = AccountEntry(id: ghostId, name: "Ghost", accountType: .other)
        let transferPlan = plan(
            income: 5000, expenses: expenses, accounts: [primary, ghost], destination: .primary
        )
        // ...but reconciliation is handed an account list without it.
        let result = BalanceReconciler.reconcile(
            plan: transferPlan, accounts: [primary], reconciledBalances: [:]
        )
        #expect(result.unknownAccountIds == [ghostId])
    }

    @Test("The server's new-month preview surfaces unallocated money in its response")
    func serverSurfacesUnallocated() {
        // Onboard with no savings-type account at all, so the remainder cannot be placed.
        var document = StoreDocument.seeded()
        document.profile = ProfileRecord(
            name: "Vlad", currencyCode: "RON", remainingMoneyDestination: .primarySavings
        )
        document.income = IncomeRecord(amount: 9000)
        document.accounts = [
            AccountRecord(
                AccountEntry(name: "Main Account", accountType: .primary, isPrimary: true),
                sortOrder: 0
            )
        ]

        let preview = NewMonthService.preview(
            NewMonthPayload(income: DecimalString(9000), reconciledBalances: nil),
            document: document,
            assembler: StateAssembler()
        )
        let unallocated = try! #require(preview.unallocatedRemainingMoney)
        #expect(unallocated.display == "9,000 RON")
    }

    @Test("The normal ground-truth scenario reports nothing unallocated")
    func groundTruthHasNoUnallocated() {
        let preview = NewMonthService.preview(
            NewMonthPayload(income: DecimalString(9000), reconciledBalances: nil),
            document: GroundTruthTests.onboardedDocument(),
            assembler: StateAssembler()
        )
        #expect(preview.unallocatedRemainingMoney == nil)
    }
}

// MARK: - Mirrored iOS defects (R26 / R26a)

/// Defects we reproduce **on purpose**. Each test fails if the values ever come out *correct*,
/// because that would be a divergence from the app we are porting — not a bug fix (R26a).
///
/// If one of these fails, do not "restore" the correct behaviour: check whether iOS was fixed
/// upstream, and if so change both sides together.
@Suite("Mirrored iOS defects")
struct MirroredDefectTests {

    /// `TransferCalculator` routes `remainingMoney` to `remainingDestination` via an `if let` with
    /// **no `else`**. With `.primarySavings` selected and no primary-savings account the money is
    /// added to no balance at all — and `isBalanced` was already computed `true` further up, so
    /// nothing flags it. Golden vector S17 pins the same thing.
    @Test("Remaining money vanishes with no primary-savings account, and isBalanced stays true")
    func remainingMoneyVanishes() throws {
        LocalePin.apply()
        var document = StoreDocument.seeded()
        document.profile = ProfileRecord(
            name: "Vlad", currencyCode: "RON", remainingMoneyDestination: .primarySavings
        )
        document.income = IncomeRecord(amount: 9000)
        document.accounts = [
            AccountRecord(
                AccountEntry(name: "Main Account", accountType: .primary, isPrimary: true),
                sortOrder: 0
            ),
            AccountRecord(
                AccountEntry(
                    name: "Emergency Fund", accountType: .emergency, emergencyMultiplier: 3.0
                ),
                sortOrder: 1
            )
        ]
        document.expenses = [ExpenseRecord(name: "Rent", amount: 4270, icon: "house.fill")]

        let plan = StateAssembler().assemble(document).transferPlan

        // The plan still claims to balance…
        #expect(plan.isBalanced == true)

        // …but the parts only add up to 5452.5 against an income of 9,000. 3,547.5 is gone.
        let parts = plan.remainsInPrimary.amount.value
            + plan.accountAllocations.reduce(Decimal(0)) { $0 + $1.amount.amount.value }
            + plan.accountExpenseTransfers.reduce(Decimal(0)) { $0 + $1.amount.amount.value }
        #expect(parts == Decimal(string: "5452.5"))

        // This inequality IS the defect. If it ever becomes an equality, iOS changed (or we
        // accidentally "fixed" it) — either way the web has diverged and this must be revisited.
        #expect(
            parts != plan.income.amount.value,
            """
            The parts now reconcile to income. That is a DIVERGENCE from iOS, not an improvement: \
            iOS drops this money (OQ8/G2/R26). Check whether Domain was fixed upstream before \
            changing anything here.
            """
        )

        // Applying the plan must not invent the money either.
        let entries = document.accounts.map { $0.toEntry() }
        let reconciliation = BalanceReconciler.reconcile(
            plan: TransferCalculator.calculate(
                income: 9000,
                expenses: [ExpenseEntry(name: "Rent", amount: 4270, icon: "house.fill")],
                allocation: document.savings.toEntry(),
                accounts: entries,
                remainingDestination: .primarySavings
            ),
            accounts: entries,
            reconciledBalances: [:]
        )
        #expect(reconciliation.balances.values.reduce(Decimal(0), +) == Decimal(string: "5452.5"))
        // The diagnostic still reports it — quarantined to dev tools, never a user warning (R26).
        #expect(reconciliation.unallocatedRemainingMoney == Decimal(string: "3547.5"))
    }

    /// The "Emergency" quick-suggestion chip creates a **`.savings`** account
    /// (`AddAccountSheet.swift:66-69`). Fails if someone "corrects" it.
    @Test("The Emergency suggestion chip still creates a savings account")
    func emergencyChipCreatesSavings() throws {
        let suggestions = StateAssembler().reference().accountSuggestions
        let emergency = try #require(suggestions.first { $0.title == "Emergency" })
        #expect(
            emergency.accountType == "savings",
            "iOS's chip creates .savings; changing it to .emergency diverges from the app (R26a)."
        )
    }

    /// `AmountFormatter.parse` replaces *all* commas with periods, so `"1,234"` is 1.234.
    @Test("parse still treats a thousands comma as a decimal point")
    func parseCommaBug() {
        #expect(AmountFormatter.parse("1,234") == Decimal(string: "1.234"))
        #expect(AmountFormatter.parse("1,234") != 1234)
    }

    /// Split mode at target — and a correction to a claim I made earlier.
    ///
    /// The two on-screen rows both named "Savings" (`+1,182 RON` and `+3,548 RON / remaining
    /// money`) are **not** two entries in `accountAllocations`. `distributeSplitToAccounts` appends
    /// a *single* savings allocation of `requested + emergencyOverflow`
    /// (`TransferCalculator.swift:441-445`); the second row is `remainingMoney`, a separate field
    /// routed by `remainingDestination`.
    ///
    /// So the collapse hazard is real but lives in the *client's* rendering, not in this DTO: a UI
    /// that renders only `accountAllocations` drops the 3,548 row entirely. `accountAllocations`
    /// is nonetheless an ordered array, and `actual*Allocation` sums rather than taking `.first`,
    /// which covers the pathological case of one account being both emergency and primary-savings.
    @Test("Split at target: one savings allocation row plus a separate remainingMoney row")
    func splitAtTargetRows() throws {
        LocalePin.apply()
        var document = StoreDocument.seeded()
        document.profile = ProfileRecord(
            name: "Vlad", currencyCode: "RON", remainingMoneyDestination: .primarySavings
        )
        document.income = IncomeRecord(amount: 9000)
        // Emergency already at target (27,000), so its split share redirects to savings.
        document.accounts = [
            AccountRecord(
                AccountEntry(name: "Main Account", accountType: .primary, isPrimary: true),
                sortOrder: 0
            ),
            AccountRecord(
                AccountEntry(
                    name: "Emergency Fund", accountType: .emergency,
                    emergencyMultiplier: 3.0, currentBalance: 27000
                ),
                sortOrder: 1
            ),
            AccountRecord(
                AccountEntry(name: "Savings", accountType: .savings, isPrimarySavings: true),
                sortOrder: 2
            )
        ]
        document.expenses = [ExpenseRecord(name: "Rent", amount: 4270, icon: "house.fill")]
        var savings = document.savings
        savings.allocationMode = .split
        savings.splitEmergencyInputMode = .percentage
        savings.splitEmergencyPercentage = 0.10
        savings.splitSavingsInputMode = .percentage
        savings.splitSavingsPercentage = 0.15
        document.savings = savings

        let state = StateAssembler().assemble(document)
        let plan = state.transferPlan
        let savingsRows = plan.accountAllocations.filter { $0.accountType == "savings" }

        // Emergency is absent entirely — not present with a zero.
        #expect(plan.accountAllocations.contains { $0.accountType == "emergency" } == false)

        // ONE savings allocation carrying the whole overflow…
        #expect(savingsRows.count == 1)
        #expect(savingsRows[0].amount.amount.text == "1182.5")

        // …and the second on-screen "Savings" row is the remainder, a separate field.
        #expect(plan.remainingMoney.amount.text == "3547.5")
        #expect(plan.remainingMoney.display == "3,548 RON")
        #expect(plan.remainingDestination == "primarySavings")

        // `actual*Allocation` sums rather than taking `.first`.
        let summed = savingsRows.reduce(Decimal(0)) { $0 + $1.amount.amount.value }
        #expect(state.settings.savings.split.actualSavingsAllocation.amount.value == summed)

        // Settings shows the *requested* total, unaffected by the fund being at target.
        #expect(state.settings.savings.split.requestedTotal.amount.text == "1182.5")
        #expect(state.settings.savings.split.emergency.resolvedAmount.amount.text == "473")
    }
}

// MARK: - Register rows the fixture cannot reach

/// The two defects found by driving the live app rather than by any test — both in code paths whose
/// only shape in `golden-vectors.json` is the *degenerate* one (no hard cap; every expense
/// categorised). Recording them here so the non-degenerate shape is now covered.
@Suite("Non-degenerate shapes")
struct NonDegenerateShapeTests {

    private func document(hardCap: Decimal?, categoryId: UUID?) -> StoreDocument {
        var document = StoreDocument.seeded()
        document.profile = ProfileRecord(name: "Vlad", currencyCode: "RON")
        document.income = IncomeRecord(amount: 9000)
        document.accounts = [
            AccountRecord(
                AccountEntry(name: "Main Account", accountType: .primary, isPrimary: true),
                sortOrder: 0
            ),
            AccountRecord(
                AccountEntry(
                    name: "Emergency Fund", accountType: .emergency,
                    emergencyMultiplier: 3.0, emergencyHardCap: hardCap, currentBalance: 1182.5
                ),
                sortOrder: 1
            )
        ]
        document.expenses = [
            ExpenseRecord(name: "Rent", amount: 4270, icon: "house.fill", categoryId: categoryId)
        ]
        return document
    }

    /// Register row 4. `EmergencyProgressCard.targetText` builds **two** captions; the
    /// `(capped at X)` half was being dropped whenever a hard cap was set.
    @Test("targetCaption keeps (capped at X) when a hard cap is set")
    func targetCaptionWithCap() throws {
        LocalePin.apply()
        let state = StateAssembler().assemble(document(hardCap: 20000, categoryId: nil))
        let fund = try #require(state.dashboard.emergencyFund)
        #expect(fund.targetCaption == "Target: 3× monthly income (capped at 20,000 RON)")
        // The cap bites, so the effective target is the cap, not 3 × 9,000.
        #expect(fund.target.amount.text == "20000")
        #expect(fund.progressPercent == 5)   // 1182.5 / 20000 = 5.91% → 5
    }

    @Test("targetCaption omits the cap clause when there is none")
    func targetCaptionWithoutCap() throws {
        LocalePin.apply()
        let state = StateAssembler().assemble(document(hardCap: nil, categoryId: nil))
        let fund = try #require(state.dashboard.emergencyFund)
        #expect(fund.targetCaption == "Target: 3× monthly income")
        #expect(fund.target.amount.text == "27000")
    }

    /// The `?? "Target"` fallback is gone: iOS never renders it (the card is gated on a target
    /// existing and the multiplier defaults to 3.0), so a bare `"Target"` could only ever be a
    /// spurious diff.
    @Test("The bare Target fallback string is never produced")
    func noBareTargetFallback() throws {
        LocalePin.apply()
        for cap in [nil, Decimal(20000), Decimal(99999)] as [Decimal?] {
            let state = StateAssembler().assemble(document(hardCap: cap, categoryId: nil))
            let fund = try #require(state.dashboard.emergencyFund)
            #expect(fund.targetCaption != "Target")
            #expect(fund.targetCaption.hasPrefix("Target: 3× monthly income"))
        }
    }

    /// `PARITY-SPEC.md §5.2` step 4. Uncategorised expenses were producing **no group at all**, so
    /// the tab rendered its empty state under a non-zero header total.
    @Test("Uncategorised expenses get a sentinel-id group, ordered last")
    func uncategorizedGroup() throws {
        LocalePin.apply()
        let state = StateAssembler().assemble(document(hardCap: nil, categoryId: nil))

        #expect(state.expensesScreen.categories.count == 1)
        let group = try #require(state.expensesScreen.categories.first)
        #expect(group.id == UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        #expect(group.category == nil)
        #expect(group.name == "Uncategorized")
        #expect(group.enabledCaption == "1/1 enabled")
        #expect(group.monthlyTotal.display == "4,270 RON")
        // The header total was always right — that was the tell.
        #expect(state.expensesScreen.totalMonthly.display == "4,270 RON")
    }

    /// Step 3: a dangling `categoryId` gets its OWN group keyed by that id, so two separately
    /// deleted categories never merge into one row.
    @Test("Dangling category ids get one group each, not a shared one")
    func danglingCategoryGroups() {
        LocalePin.apply()
        let ghostA = UUID(uuidString: "FFFFFFFF-0000-0000-0000-00000000000A")!
        let ghostB = UUID(uuidString: "FFFFFFFF-0000-0000-0000-00000000000B")!
        var document = self.document(hardCap: nil, categoryId: ghostA)
        document.expenses.append(
            ExpenseRecord(name: "Gym", amount: 100, icon: "heart.fill", categoryId: ghostB, sortOrder: 1)
        )
        document.expenses.append(
            ExpenseRecord(name: "Coffee", amount: 50, icon: "cup.and.saucer.fill", sortOrder: 2)
        )

        let groups = StateAssembler().assemble(document).expensesScreen.categories
        // Two dangling groups + one uncategorized — never collapsed into one.
        #expect(groups.count == 3)
        #expect(groups.map(\.id) == [ghostA, ghostB, Defaults.uncategorizedGroupId])
        #expect(groups.allSatisfy { $0.category == nil })
        #expect(groups.allSatisfy { $0.name == "Uncategorized" })
        // Uncategorized is last (step 4 after step 3).
        #expect(groups.last?.id == Defaults.uncategorizedGroupId)
    }

    /// Known categories come first, in `sortOrder`, then dangling, then uncategorized.
    @Test("Group ordering is known → dangling → uncategorized")
    func groupOrdering() {
        LocalePin.apply()
        let ghost = UUID(uuidString: "FFFFFFFF-0000-0000-0000-00000000000A")!
        var document = self.document(hardCap: nil, categoryId: Domain.Category.housing.id)
        document.expenses.append(
            ExpenseRecord(name: "Food", amount: 200, icon: "cart.fill",
                          categoryId: Domain.Category.foodGroceries.id, sortOrder: 1)
        )
        document.expenses.append(
            ExpenseRecord(name: "Gym", amount: 100, icon: "heart.fill", categoryId: ghost, sortOrder: 2)
        )
        document.expenses.append(
            ExpenseRecord(name: "Coffee", amount: 50, icon: "cup.and.saucer.fill", sortOrder: 3)
        )

        let groups = StateAssembler().assemble(document).expensesScreen.categories
        // Housing sortOrder 3, Food/Groceries 6 → Housing first.
        #expect(groups.map(\.name) == ["Housing", "Food/Groceries", "Uncategorized", "Uncategorized"])
        #expect(groups.map(\.id) == [
            Domain.Category.housing.id, Domain.Category.foodGroceries.id,
            ghost, Defaults.uncategorizedGroupId
        ])
    }

    /// S28, pinned by Reviewer *before* the defect was written. A zero expense total must render
    /// `"0 RON"`, never `"-0 RON"` — iOS gates the minus on `amount > 0`.
    ///
    /// The guard keys off the **amount**, not `display == "0 RON"`. A string test would also strip
    /// the sign from a genuinely small negative, whose `"-0 RON"` we reproduce on purpose (R24).
    @Test("A zero expense total renders unsigned; a small negative keeps its sign")
    func negatedDisplayNeverMinusZero() {
        LocalePin.apply()
        #expect(negatedDisplay(Money(4270, currency: "RON")) == "-4,270 RON")
        #expect(negatedDisplay(Money(0, currency: "RON")) == "0 RON")
        // R24: a real negative still displays as "-0 RON" — the sign is information, not noise.
        let tiny = Money(Decimal(string: "-0.004")!, currency: "RON")
        #expect(tiny.display == "-0 RON")
        #expect(negatedDisplay(tiny) == "-0 RON")
    }

    /// The whole-state path: Skip-for-now on the expenses step persists zero expense rows, so the
    /// Dashboard's expenses row is exactly the zero case.
    @Test("Skip-for-now yields a zero total that renders unsigned end to end")
    func zeroTotalFromSkip() {
        LocalePin.apply()
        var document = StoreDocument.seeded()
        document.profile = ProfileRecord(name: "Vlad", currencyCode: "RON")
        document.income = IncomeRecord(amount: 9000)
        document.accounts = [
            AccountRecord(
                AccountEntry(name: "Main Account", accountType: .primary, isPrimary: true),
                sortOrder: 0
            )
        ]
        // No expenses at all — `where amount > 0` drops every skipped row.
        let state = StateAssembler().assemble(document)
        #expect(state.dashboard.summary.expenses.display == "0 RON")
        #expect(state.dashboard.summary.expensesNegativeDisplay == "0 RON")
        #expect(state.dashboard.summary.expenses.isZero == true)
        // availableIncome == income when nothing is spent.
        #expect(state.transferPlan.availableIncome.amount.text == "9000")
    }
}

// MARK: - R30 completion strings

/// The two completion strings are **not** interchangeable, which is why no unified
/// `completionCaption` is served: same `isComplete` flag, different wording, different structure
/// (replace vs append), and different conditions.
@Suite("R30 completion strings")
struct CompletionStringTests {

    /// Emergency fund exactly at target after this month's allocation.
    private func completingState() -> AppStateResponse {
        LocalePin.apply()
        var document = StoreDocument.seeded()
        document.profile = ProfileRecord(name: "Vlad", currencyCode: "RON")
        document.income = IncomeRecord(amount: 9000)
        document.accounts = [
            AccountRecord(
                AccountEntry(name: "Main Account", accountType: .primary, isPrimary: true),
                sortOrder: 0
            ),
            AccountRecord(
                // 100 short of the 27,000 target, so the allocation completes it.
                AccountEntry(
                    name: "Emergency Fund", accountType: .emergency,
                    emergencyMultiplier: 3.0, currentBalance: 26900
                ),
                sortOrder: 1
            ),
            AccountRecord(
                AccountEntry(name: "Savings", accountType: .savings, isPrimarySavings: true),
                sortOrder: 2
            )
        ]
        document.expenses = [ExpenseRecord(name: "Rent", amount: 4270, icon: "house.fill")]
        return StateAssembler().assemble(document)
    }

    @Test("A completing emergency allocation gets both notes, with their different semantics")
    func completingAllocation() throws {
        let state = completingState()
        let allocation = try #require(
            state.transferPlan.accountAllocations.first { $0.accountType == "emergency" }
        )
        #expect(allocation.isComplete == true)
        #expect(allocation.amount.amount.text == "100")     // capped at the remaining need
        #expect(allocation.progressAfterPercent == 100)

        // New Month: the note REPLACES the progress string.
        #expect(allocation.newMonthNote == "Completes fund to 100%!")
        #expect(allocation.newMonthNote != allocation.progressChangeDisplay)

        // Onboarding: the label is APPENDED, so the progress string survives alongside it.
        #expect(allocation.onboardingCompletionNote == "Target reached!")
        #expect(allocation.progressChangeDisplay == "99% → 100%")
        #expect(allocation.progressChangeTone == "positive")
    }

    @Test("An incomplete allocation falls back to the progress string on New Month")
    func incompleteAllocation() throws {
        LocalePin.apply()
        let state = GroundTruthTests.onboardedState()
        let allocation = try #require(state.transferPlan.accountAllocations.first)
        #expect(allocation.isComplete == false)
        // New Month renders the progress string when not complete.
        #expect(allocation.newMonthNote == allocation.progressChangeDisplay)
        #expect(allocation.newMonthNote == "4% → 8%")
        // Onboarding appends nothing, and the progress text is orange, not green.
        #expect(allocation.onboardingCompletionNote == nil)
        #expect(allocation.progressChangeTone == "warning")
    }

    /// A completed emergency fund produces an allocation with **`amount = 0`** in prioritized mode
    /// (appended because `targetAmount != nil`, `TransferCalculator.swift:109-112`) but **no
    /// allocation at all** in split mode (`:176-178`). So `accountAllocations` differs in *length*
    /// between modes for the same accounts — anything assembled per-allocation must tolerate both.
    @Test("A full emergency fund yields a zero-amount row in priority, no row in split")
    func fullFundDiffersByMode() {
        LocalePin.apply()

        func state(mode: AllocationMode) -> AppStateResponse {
            var document = StoreDocument.seeded()
            document.profile = ProfileRecord(name: "Vlad", currencyCode: "RON")
            document.income = IncomeRecord(amount: 9000)
            document.accounts = [
                AccountRecord(
                    AccountEntry(name: "Main Account", accountType: .primary, isPrimary: true),
                    sortOrder: 0
                ),
                AccountRecord(
                    AccountEntry(
                        name: "Emergency Fund", accountType: .emergency,
                        emergencyMultiplier: 3.0, currentBalance: 27000
                    ),
                    sortOrder: 1
                ),
                AccountRecord(
                    AccountEntry(name: "Savings", accountType: .savings, isPrimarySavings: true),
                    sortOrder: 2
                )
            ]
            document.expenses = [ExpenseRecord(name: "Rent", amount: 4270, icon: "house.fill")]
            var savings = document.savings
            savings.allocationMode = mode
            if mode == .split {
                savings.splitEmergencyInputMode = .percentage
                savings.splitEmergencyPercentage = 0.10
                savings.splitSavingsInputMode = .percentage
                savings.splitSavingsPercentage = 0.15
            }
            document.savings = savings
            return StateAssembler().assemble(document)
        }

        // Prioritized: the row exists with amount 0, and carries the completion wording.
        let priority = state(mode: .prioritized)
        let priorityEmergency = priority.transferPlan.accountAllocations
            .first { $0.accountType == "emergency" }
        #expect(priorityEmergency != nil)
        #expect(priorityEmergency?.amount.amount.text == "0")
        #expect(priorityEmergency?.amount.isZero == true)
        #expect(priorityEmergency?.isComplete == true)
        #expect(priorityEmergency?.newMonthNote == "Completes fund to 100%!")
        // The zero amount must not acquire a sign.
        #expect(priorityEmergency?.amount.display == "0 RON")

        // Split: no emergency row at all — a shorter array for the same accounts.
        let split = state(mode: .split)
        #expect(split.transferPlan.accountAllocations.contains { $0.accountType == "emergency" } == false)
        #expect(split.transferPlan.accountAllocations.count < priority.transferPlan.accountAllocations.count)
        // Assembly tolerates the absence: the split block reports 0 rather than crashing or skipping.
        #expect(split.settings.savings.split.actualEmergencyAllocation.amount.text == "0")
    }

    /// The "Monthly Equivalent" row is `amount × Frequency.annual.monthlyMultiplier`, i.e.
    /// **× (1/12)** — a *division*, not the `× 12` R18 recorded. Getting the direction wrong is a
    /// **144×** error (12× the wrong way), so this pins the direction and the rounding.
    /// ⚠️ A subtler consequence of the 28-digit multiplier, found while writing this test: an
    /// exact `.5` is **unreachable** through the annual path. `1266 / 12` is mathematically
    /// `105.5`, but `1266 × Decimal(1)/12` is `105.4999…`, so it rounds **down to 105** — not up
    /// to 106 as half-even on a true 105.5 would give. A JS `1266 / 12` yields exactly `105.5` and
    /// would then round to 106, disagreeing with iOS by 1.
    ///
    /// So this row is not merely "don't divide in JS" — dividing produces a *different value* at
    /// the boundary, in a way no amount of careful rounding in TypeScript recovers.
    @Test("Monthly Equivalent divides by the Decimal constant, tail and all", arguments: [
        // annual amount, expected monthly display, expected annual display
        ("1200", "100 RON", "1,200 RON"),
        // 1250/12 = 104.1666… → 104
        ("1250", "104 RON", "1,250 RON"),
        // True 105.5 would round half-even UP to 106; the multiplier gives 105.4999… → 105.
        ("1266", "105 RON", "1,266 RON"),
        // True 104.5 would round half-even to 104; the multiplier gives 104.4999… → 104 too.
        ("1254", "104 RON", "1,254 RON")
    ])
    func monthlyEquivalentDivides(amount: String, monthly: String, annual: String) {
        LocalePin.apply()
        let entry = ExpenseEntry(
            name: "Insurance", amount: Decimal(string: amount)!, frequency: .annual, icon: "x"
        )
        #expect(Money(entry.monthlyAmount, currency: "RON").display == monthly)
        #expect(Money(entry.annualAmount, currency: "RON").display == annual)

        // The `× 12` the R18 exception described would have produced this instead — 144× out.
        let wrong = Money(entry.amount * 12, currency: "RON")
        #expect(wrong.display != monthly)

        // And a JS-style true division disagrees at the .5 boundary, which is the deeper reason
        // this cannot be done client-side at all.
        let trueDivision = entry.amount / 12
        if trueDivision != entry.monthlyAmount {
            #expect(entry.monthlyAmount < trueDivision)
        }
    }

    /// A monthly expense's "Monthly Equivalent" is the amount unchanged, and the row is not shown.
    @Test("A monthly expense shows no Monthly Equivalent row")
    func monthlyEquivalentHiddenWhenMonthly() {
        LocalePin.apply()
        let entry = ExpenseEntry(name: "Rent", amount: 2500, frequency: .monthly, icon: "x")
        #expect(entry.monthlyAmount == 2500)
        #expect(Money(entry.annualAmount, currency: "RON").display == "30,000 RON")
    }

    /// A reachable state where the section gate and the row loop disagree: prioritized mode,
    /// emergency fund at target, **no savings account**.
    ///
    /// `hasAccountAllocations` is `false` (it requires some `amount > 0`) while `accountAllocations`
    /// is **non-empty** — it holds a zero-amount emergency row, appended because `targetAmount`
    /// exists. And `remainingMoney` is 4,730, so there is money to show. Nothing may assume a
    /// correlation between the gate and the array's length, and length also varies by mode.
    @Test("hasAccountAllocations can be false while accountAllocations is non-empty")
    func gateAndArrayDisagree() throws {
        LocalePin.apply()
        var document = StoreDocument.seeded()
        document.profile = ProfileRecord(
            name: "Vlad", currencyCode: "RON", remainingMoneyDestination: .primarySavings
        )
        document.income = IncomeRecord(amount: 9000)
        // No savings account at all.
        document.accounts = [
            AccountRecord(
                AccountEntry(name: "Main Account", accountType: .primary, isPrimary: true),
                sortOrder: 0
            ),
            AccountRecord(
                AccountEntry(
                    name: "Emergency Fund", accountType: .emergency,
                    emergencyMultiplier: 3.0, currentBalance: 27000
                ),
                sortOrder: 1
            )
        ]
        document.expenses = [ExpenseRecord(name: "Rent", amount: 4270, icon: "house.fill")]

        let plan = StateAssembler().assemble(document).transferPlan

        // The gate says "nothing to show"…
        #expect(plan.hasAccountAllocations == false)
        // …while the array holds a row, with amount 0.
        #expect(plan.accountAllocations.count == 1)
        let row = try #require(plan.accountAllocations.first)
        #expect(row.accountType == "emergency")
        #expect(row.amount.amount.text == "0")
        #expect(row.amount.isZero == true)
        #expect(row.isComplete == true)
        // …and there is real money in play, which is why the disagreement matters.
        #expect(plan.remainingMoney.amount.text == "4730")
        // This is also the R26 vanishing case: no primary-savings account to receive it.
        #expect(plan.isBalanced == true)
        #expect(plan.totalAccountAllocations.amount.text == "0")
    }

    /// The New Month note is gated on `accountType == .emergency`; the onboarding one is not.
    /// A complete *savings* allocation therefore behaves differently on the two screens — which is
    /// exactly why a single unified field would be wrong.
    @Test("The two conditions differ: New Month is emergency-only, onboarding is not")
    func conditionsDiffer() {
        let state = completingState()
        for allocation in state.transferPlan.accountAllocations where allocation.accountType != "emergency" {
            // Non-emergency rows never get the New Month completion wording…
            #expect(allocation.newMonthNote != "Completes fund to 100%!")
            // …and with no progress fields there is nothing to append to either.
            if allocation.progressChangeDisplay == nil {
                #expect(allocation.onboardingCompletionNote == nil)
                #expect(allocation.progressChangeTone == nil)
            }
        }
    }
}
