import Domain
import Foundation
import Utilities

/// Turns a `StoreDocument` into the API response.
///
/// **This file assembles; it does not calculate.** Every monetary figure comes out of
/// `Domain.TransferCalculator` or `Domain.AccountEntry`, every string out of
/// `Utilities.AmountFormatter` or a Domain `displayName`. That is the whole reason the server
/// exists rather than a TypeScript reimplementation — there is exactly one copy of the maths and
/// iOS compiles the same one. If you find yourself writing an arithmetic operator here that
/// isn't a straight sum for a display total, it belongs in `Domain` instead.
public struct StateAssembler: Sendable {

    let pickers = PickerAssembler()

    public init() {}

    // MARK: - Entry point

    public func assemble(_ document: StoreDocument, now: Date = Date()) -> AppStateResponse {
        let currency = document.currency
        let money = MoneyFormatter(currency: currency)
        let income = document.monthlyIncome

        let accountEntries = document.accounts.map { $0.toEntry() }
        let allocation = document.savings.toEntry()

        // The Dashboard feeds the calculator **enabled expenses, pre-normalised to monthly**
        // (`MainTabView.loadDashboardData` filters `isEnabled` and maps `monthlyAmount`), because
        // `TransferCalculator.totalExpenses` sums raw `amount` and would otherwise count an
        // annual expense at its full annual value. Reproduced exactly.
        let planExpenses = document.expenses
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
            income: income,
            expenses: planExpenses,
            allocation: allocation,
            accounts: accountEntries,
            remainingDestination: document.profile?.remainingMoneyDestination ?? .primarySavings
        )

        let sortedAccounts = document.accounts.sorted {
            ($0.sortOrder, $0.createdAt) < ($1.sortOrder, $1.createdAt)
        }
        let accountDTOs = sortedAccounts.map { account(from: $0, income: income, money: money) }

        let sortedExpenses = document.expenses.sorted {
            ($0.sortOrder, $0.createdAt) < ($1.sortOrder, $1.createdAt)
        }
        let expenseDTOs = sortedExpenses.map { expenseDTO(from: $0, document: document, money: money) }

        let categoryDTOs = document.categories
            .sorted { ($0.sortOrder, $0.createdAt, $0.name) < ($1.sortOrder, $1.createdAt, $1.name) }
            .map(category(from:))

        return AppStateResponse(
            schemaVersion: document.schemaVersion,
            onboardingCompleted: document.onboardingCompleted,
            profile: document.profile.map { profile(from: $0, currency: currency) },
            settings: settings(document: document, money: money, plan: plan),
            accounts: accountDTOs,
            expenses: expenseDTOs,
            categories: categoryDTOs,
            dashboard: dashboard(
                document: document,
                plan: plan,
                accountDTOs: accountDTOs,
                money: money,
                income: income,
                now: now
            ),
            expensesScreen: expensesScreen(
                document: document,
                expenseDTOs: expenseDTOs,
                money: money
            ),
            transferPlan: transferPlan(plan, money: money),
            reference: reference()
        )
    }

    // MARK: - Profile & settings

    private func profile(from record: ProfileRecord, currency: Currency) -> ProfileDTO {
        ProfileDTO(
            name: record.name,
            currencyCode: record.currencyCode,
            currencyDisplayName: currency.displayName,
            remainingMoneyDestination: record.remainingMoneyDestination.rawValue,
            remainingMoneyDestinationDisplayName: record.remainingMoneyDestination.displayName,
            createdAt: record.createdAt
        )
    }

    private func settings(
        document: StoreDocument,
        money: MoneyFormatter,
        plan: TransferPlan
    ) -> SettingsDTO {
        let entry = document.savings.toEntry()
        let availableIncome = plan.availableIncome
        return SettingsDTO(
            income: money(document.monthlyIncome),
            savings: SavingsDTO(
                percentage: entry.percentage,
                percentageDisplay: entry.percentageDisplay,
                effectivePercentage: entry.effectivePercentage,
                effectivePercentageDisplay: entry.effectivePercentageDisplay,
                boostEnabled: entry.boostEnabled,
                boostMultiplier: entry.boostMultiplier,
                isBoostApplicable: entry.isBoostApplicable,
                allocationMode: entry.allocationMode.rawValue,
                allocationModeDisplayName: entry.allocationMode.displayName,
                allocationModeDescription: entry.allocationMode.description,
                savingsInputMode: entry.savingsInputMode.rawValue,
                fixedAmount: money(entry.fixedAmount),
                splitEmergencyInputMode: entry.splitEmergencyInputMode.rawValue,
                splitEmergencyAmount: money(entry.splitEmergencyAmount),
                splitEmergencyPercentage: entry.splitEmergencyPercentage,
                splitSavingsInputMode: entry.splitSavingsInputMode.rawValue,
                splitSavingsAmount: money(entry.splitSavingsAmount),
                splitSavingsPercentage: entry.splitSavingsPercentage,
                isValid: entry.isValid,
                boostedPercentDisplay: pickers.boostedPercentDisplay(entry),
                savingsSliderPositions: pickers.savingsSliderPositions(
                    allocation: entry, availableIncome: availableIncome, money: money
                ),
                splitSliderPositions: pickers.splitSliderPositions(
                    availableIncome: availableIncome, money: money
                ),
                split: pickers.split(
                    allocation: entry, availableIncome: availableIncome, plan: plan, money: money
                )
            )
        )
    }

    // MARK: - Accounts

    func account(from record: AccountRecord, income: Decimal, money: MoneyFormatter) -> AccountDTO {
        account(from: record.toEntry(), sortOrder: record.sortOrder, income: income, money: money)
    }

    func account(
        from entry: AccountEntry,
        sortOrder: Int,
        income: Decimal,
        money: MoneyFormatter
    ) -> AccountDTO {
        let target = entry.emergencyTarget(monthlyIncome: income)
        let progress = entry.emergencyProgress(monthlyIncome: income)
        return AccountDTO(
            id: entry.id,
            name: entry.name,
            purpose: entry.purpose,
            accountType: entry.accountType.rawValue,
            accountTypeDisplayName: entry.accountType.displayName,
            accountTypeDescription: entry.accountType.description,
            icon: entry.accountType.icon,
            isPrimary: entry.isPrimary,
            isPrimarySavings: entry.isPrimarySavings,
            emergencyMultiplier: entry.emergencyMultiplier,
            emergencyHardCap: money(entry.emergencyHardCap),
            currentBalance: money(entry.currentBalance),
            sortOrder: sortOrder,
            emergencyTarget: money(target),
            emergencyProgress: progress,
            emergencyProgressPercent: progress.map(truncatedPercent),
            emergencyProgressDisplay: progress.map(percentDisplay),
            isEmergencyComplete: entry.isEmergencyComplete(monthlyIncome: income),
            subtitleParts: subtitleParts(for: entry, money: money),
            emergencyTargetUncapped: money(uncappedTarget(for: entry, income: income)),
            isCapActive: isCapActive(for: entry, income: income),
            multiplierOptions: entry.accountType == .emergency
                ? pickers.multiplierOptions(
                    selected: entry.emergencyMultiplier,
                    hardCap: entry.emergencyHardCap,
                    monthlyIncome: income,
                    money: money
                )
                : [],
            isReconcilable: isReconcilable(entry.accountType),
            wasLastMonthDisplay: "was \(money(entry.currentBalance).display) last month",
            balanceEditorValue: pickers.balanceEditorValue(entry.currentBalance)
        )
    }

    /// `income × multiplier` before the hard cap — obtained from Domain by asking for the target
    /// with the cap removed, rather than multiplying here.
    private func uncappedTarget(for entry: AccountEntry, income: Decimal) -> Decimal? {
        guard entry.accountType == .emergency, let multiplier = entry.emergencyMultiplier else {
            return nil
        }
        return AccountEntry(
            name: entry.name, accountType: .emergency,
            emergencyMultiplier: multiplier, emergencyHardCap: nil
        ).emergencyTarget(monthlyIncome: income)
    }

    private func isCapActive(for entry: AccountEntry, income: Decimal) -> Bool {
        guard let capped = entry.emergencyTarget(monthlyIncome: income),
              let uncapped = uncappedTarget(for: entry, income: income)
        else { return false }
        return capped < uncapped
    }

    /// New Month step 2 only lets these three types be edited
    /// (`ReconcileAccountsStep.swift:30-36`).
    private func isReconcilable(_ type: AccountType) -> Bool {
        type == .emergency || type == .savings || type == .personal
    }

    /// The Settings > Accounts row subtitle, reproducing `SettingsSheet.swift:373-388` run for
    /// run — including each run's colour and its own leading bullet (R23/R27).
    ///
    /// Note the multiplier badge is gated on `emergencyMultiplier != nil`, **not** on
    /// `accountType == .emergency` — so a non-emergency account carrying a stray multiplier still
    /// shows it, exactly as iOS does.
    private func subtitleParts(for entry: AccountEntry, money: MoneyFormatter) -> [SubtitlePartDTO] {
        var parts = [SubtitlePartDTO(text: entry.accountType.displayName, tone: "secondary")]

        if entry.isPrimarySavings {
            parts.append(
                SubtitlePartDTO(text: "• " + AccountType.primary.displayName, tone: "accentPrimary")
            )
        }

        if let multiplier = entry.emergencyMultiplier {
            // `SettingsSheet.swift:428-437` — the cap is spelled out inline when present.
            let base = "• \(formatMultiplier(multiplier))× income"
            let text = entry.emergencyHardCap
                .map { "\(base) (max \(money($0).display))" } ?? base
            parts.append(SubtitlePartDTO(text: text, tone: "accentSecondary"))
        }

        return parts
    }

    /// iOS renders the multiplier as `Int(multiplier)` everywhere it appears
    /// (`EmergencyProgressCard.swift:73`, `SettingsSheet.swift:429`) — **truncating**, so a 3.5
    /// would render `"3"`. The picker only offers 3/4/5/6 so it never differs in practice, but
    /// matching the truncation keeps a hand-set multiplier faithful.
    private func formatMultiplier(_ value: Double) -> String {
        String(Int(value))
    }

    /// `EmergencyProgressCard.targetText` (`:71-85`) — **two** captions, not one.
    ///
    /// The `(capped at X)` half was previously dropped, silently, whenever a hard cap was set.
    /// There is deliberately no "no multiplier" fallback: `emergencyTarget` is `nil` without a
    /// multiplier and the card is gated on a target existing, so that branch is unreachable and a
    /// bare `"Target"` string could only ever surface as a spurious diff.
    private func targetCaption(
        multiplier: Double?,
        hardCap: Decimal?,
        money: MoneyFormatter
    ) -> String {
        let count = formatMultiplier(multiplier ?? Defaults.emergencyMultiplier)
        guard let hardCap else {
            return "Target: \(count)× monthly income"
        }
        return "Target: \(count)× monthly income (capped at \(money(hardCap).display))"
    }

    // MARK: - Expenses

    private func expenseDTO(
        from record: ExpenseRecord,
        document: StoreDocument,
        money: MoneyFormatter
    ) -> ExpenseDTO {
        let entry = record.toEntry()
        let categoryRecord = record.categoryId.flatMap { id in
            document.categories.first { $0.id == id }
        }
        return ExpenseDTO(
            id: entry.id,
            name: entry.name,
            amount: money(entry.amount),
            frequency: entry.frequency.rawValue,
            frequencyDisplayName: entry.frequency.displayName,
            frequencyIcon: entry.frequency.icon,
            monthlyAmount: money(entry.monthlyAmount),
            annualAmount: money(entry.annualAmount),
            icon: entry.icon,
            categoryId: entry.categoryId,
            category: categoryRecord.map(category(from:)),
            linkedAccountId: entry.linkedAccountId,
            linkedAccountName: linkedAccountName(for: entry.linkedAccountId, in: document),
            isEnabled: entry.isEnabled,
            notes: entry.notes,
            sortOrder: record.sortOrder
        )
    }

    /// `nil` means the primary account (iOS convention). A dangling id yields `"Unknown"` —
    /// the same non-localized fallback `TransferCalculator.distributeExpenses` uses, because
    /// `linkedAccountId` is a loose UUID with no referential integrity.
    private func linkedAccountName(for id: UUID?, in document: StoreDocument) -> String {
        guard let id else {
            return document.accounts.first(where: \.isPrimary)?.name ?? "Unknown"
        }
        return document.accounts.first { $0.id == id }?.name ?? "Unknown"
    }

    private func category(from record: CategoryRecord) -> CategoryDTO {
        CategoryDTO(
            id: record.id,
            name: record.name,
            icon: record.icon,
            colorHex: record.colorHex,
            isDefault: record.isDefault,
            sortOrder: record.sortOrder
        )
    }

    // MARK: - Dashboard

    private func dashboard(
        document: StoreDocument,
        plan: TransferPlan,
        accountDTOs: [AccountDTO],
        money: MoneyFormatter,
        income: Decimal,
        now: Date
    ) -> DashboardDTO {
        // `SummaryCard` is fed exactly these two plan fields on iOS — savings is the plan's
        // *allocated* total and personal spending is its remaining money. Not recomputed.
        let summary = MonthlySummaryDTO(
            income: money(income),
            expenses: money(plan.totalExpenses),
            expensesNegativeDisplay: negatedDisplay(money(plan.totalExpenses)),
            savings: money(plan.totalSavings),
            personalSpending: money(plan.remainingMoney)
        )

        return DashboardDTO(
            currentMonthDisplay: DateFormatters.monthYear.string(from: now),
            summary: summary,
            emergencyFund: emergencyFund(document: document, income: income, money: money),
            primaryAccount: accountDTOs.first { $0.isPrimary },
            otherAccounts: accountDTOs.filter { !$0.isPrimary },
            expenseBreakdown: expenseBreakdown(
                document: document,
                totalExpenses: plan.totalExpenses,
                money: money
            )
        )
    }

    private func emergencyFund(
        document: StoreDocument,
        income: Decimal,
        money: MoneyFormatter
    ) -> EmergencyFundDTO? {
        guard let record = document.accounts.first(where: { $0.accountType == .emergency }) else {
            return nil
        }
        let entry = record.toEntry()
        guard let target = entry.emergencyTarget(monthlyIncome: income) else { return nil }
        let progress = entry.emergencyProgress(monthlyIncome: income) ?? 0
        let multiplier = entry.emergencyMultiplier

        return EmergencyFundDTO(
            accountId: entry.id,
            accountName: entry.name,
            balance: money(entry.currentBalance),
            target: money(target),
            progress: progress,
            progressPercent: truncatedPercent(progress),
            progressDisplay: percentDisplay(progress),
            multiplier: multiplier,
            targetCaption: targetCaption(
                multiplier: multiplier, hardCap: entry.emergencyHardCap, money: money
            ),
            isComplete: entry.isEmergencyComplete(monthlyIncome: income)
        )
    }

    /// `ExpenseBreakdownCard`: enabled expenses with a positive monthly amount, sorted
    /// descending, **capped at 5**, percent `Int((amount / total) * 100)` — truncated, which is
    /// why Streaming's `120/4270 = 2.81%` renders as `2%` and not `3%`.
    private func expenseBreakdown(
        document: StoreDocument,
        totalExpenses: Decimal,
        money: MoneyFormatter
    ) -> [ExpenseBreakdownItemDTO] {
        let total = NSDecimalNumber(decimal: totalExpenses).doubleValue

        return document.expenses
            .filter(\.isEnabled)
            .map { (record: $0, monthly: $0.toEntry().monthlyAmount) }
            .filter { $0.monthly > 0 }
            .sorted { $0.monthly > $1.monthly }
            .prefix(5)
            .map { item in
                let percent: Int = total > 0
                    ? Int((NSDecimalNumber(decimal: item.monthly).doubleValue / total) * 100)
                    : 0
                return ExpenseBreakdownItemDTO(
                    id: item.record.id,
                    name: item.record.name,
                    icon: item.record.icon,
                    amount: money(item.monthly),
                    percent: percent,
                    percentDisplay: "\(percent)%"
                )
            }
    }

    // MARK: - Expenses screen

    /// The Expenses tab's groups, reproducing `ExpensesViewModel.swift:291-327` step for step:
    ///
    /// 1. bucket by `categoryId`, `nil` → uncategorized;
    /// 2. a group per **known** category that has expenses, in `sortOrder`;
    /// 3. then a group per **unknown** `categoryId` (category since deleted), `category: nil`,
    ///    `id` = the dangling id;
    /// 4. then the uncategorized group, if any, with the sentinel id.
    ///
    /// Steps 3 and 4 were previously missing entirely, so four uncategorized expenses produced
    /// **no groups at all** — the tab rendered its empty state under a non-zero header total.
    private func expensesScreen(
        document: StoreDocument,
        expenseDTOs: [ExpenseDTO],
        money: MoneyFormatter
    ) -> ExpensesScreenDTO {
        let enabled = document.expenses.filter(\.isEnabled).map { $0.toEntry() }
        // Totals are over ALL expenses and are search-independent (R14 gap 4).
        let totalMonthly = enabled.reduce(Decimal(0)) { $0 + $1.monthlyAmount }
        let totalAnnual = enabled.reduce(Decimal(0)) { $0 + $1.annualAmount }

        let byCategory = Dictionary(grouping: expenseDTOs) { $0.categoryId }
        let knownIds = Set(document.categories.map(\.id))

        func group(
            id: UUID,
            category: CategoryDTO?,
            name: String,
            items: [ExpenseDTO]
        ) -> ExpenseCategoryGroupDTO {
            let enabledItems = items.filter(\.isEnabled)
            return ExpenseCategoryGroupDTO(
                id: id,
                category: category,
                name: name,
                enabledCount: enabledItems.count,
                totalCount: items.count,
                // `"\(enabledCount)/\(expenses.count) enabled"` — the denominator is ALL expenses
                // in the group, not just the enabled ones.
                enabledCaption: "\(enabledItems.count)/\(items.count) enabled",
                monthlyTotal: money(enabledItems.reduce(Decimal(0)) { $0 + $1.monthlyAmount.amount.value }),
                annualTotal: money(enabledItems.reduce(Decimal(0)) { $0 + $1.annualAmount.amount.value }),
                expenses: items
            )
        }

        // Step 2 — known categories with expenses, in sortOrder.
        var groups: [ExpenseCategoryGroupDTO] = document.categories
            .sorted { ($0.sortOrder, $0.createdAt, $0.name) < ($1.sortOrder, $1.createdAt, $1.name) }
            .compactMap { record in
                guard let items = byCategory[record.id], !items.isEmpty else { return nil }
                let dto = category(from: record)
                return group(id: record.id, category: dto, name: dto.name, items: items)
            }

        // Step 3 — dangling category ids, each its own group so two deleted categories never merge.
        let danglingIds = byCategory.keys
            .compactMap { $0 }
            .filter { !knownIds.contains($0) }
            .sorted { $0.uuidString < $1.uuidString }
        for id in danglingIds {
            guard let items = byCategory[id], !items.isEmpty else { continue }
            groups.append(group(id: id, category: nil, name: Defaults.uncategorizedName, items: items))
        }

        // Step 4 — uncategorized, last.
        if let items = byCategory[nil], !items.isEmpty {
            groups.append(
                group(
                    id: Defaults.uncategorizedGroupId,
                    category: nil,
                    name: Defaults.uncategorizedName,
                    items: items
                )
            )
        }

        return ExpensesScreenDTO(
            totalMonthly: money(totalMonthly),
            totalAnnual: money(totalAnnual),
            categories: groups
        )
    }

    // MARK: - Transfer plan

    func transferPlan(_ plan: TransferPlan, money: MoneyFormatter) -> TransferPlanDTO {
        TransferPlanDTO(
            income: money(plan.income),
            totalExpenses: money(plan.totalExpenses),
            availableIncome: money(plan.availableIncome),
            totalSavings: money(plan.totalSavings),
            // Priority order (emergency first, then savings) is meaningful — never sorted.
            accountAllocations: plan.accountAllocations.map { allocation in
                AccountAllocationDTO(
                    accountId: allocation.accountId,
                    accountName: allocation.accountName,
                    accountType: allocation.accountType.rawValue,
                    icon: allocation.icon,
                    amount: money(allocation.amount),
                    progressBefore: allocation.progressBefore,
                    progressAfter: allocation.progressAfter,
                    progressBeforePercent: allocation.progressBefore.map(truncatedPercent),
                    progressAfterPercent: allocation.progressAfter.map(truncatedPercent),
                    progressChangeDisplay: allocation.progressChangeDisplay,
                    // Replacement semantics, emergency-only (New Month).
                    newMonthNote: allocation.accountType == .emergency && allocation.isComplete
                        ? "Completes fund to 100%!"
                        : allocation.progressChangeDisplay,
                    // Append semantics, any account type, gated on a progress string (Onboarding).
                    onboardingCompletionNote: allocation.progressChangeDisplay != nil
                        && allocation.isComplete ? "Target reached!" : nil,
                    progressChangeTone: allocation.progressChangeDisplay == nil
                        ? nil
                        : (allocation.isComplete ? "positive" : "warning"),
                    targetAmount: money(allocation.targetAmount),
                    currentBalance: money(allocation.currentBalance),
                    isComplete: allocation.isComplete
                )
            },
            remainsInPrimary: money(plan.remainsInPrimary),
            // Domain builds this by iterating a `Dictionary(grouping:)`, so its order is
            // nondeterministic. Sorting by account name here is what stops the web UI from
            // reshuffling rows between otherwise identical requests (`DECISIONS.md` D1 ⚠️).
            accountExpenseTransfers: plan.accountExpenseTransfers
                .sorted { ($0.accountName, $0.accountId.uuidString) < ($1.accountName, $1.accountId.uuidString) }
                .map { transfer in
                    AccountExpenseTransferDTO(
                        accountId: transfer.accountId,
                        accountName: transfer.accountName,
                        amount: money(transfer.amount),
                        expenseNames: transfer.expenseNames
                    )
                },
            remainingMoney: money(plan.remainingMoney),
            remainingDestination: plan.remainingDestination.rawValue,
            remainingDestinationDisplayName: plan.remainingDestination.displayName,
            isBalanced: plan.isBalanced,
            hasAccountAllocations: plan.hasAccountAllocations,
            totalAccountAllocations: money(plan.totalAccountAllocations),
            summary: plan.summary
        )
    }

    // MARK: - Reference

    /// Enum tables straight out of Domain's `allCases`, which **is** the order iOS renders
    /// pickers in. Generated, never transcribed, so a new enum case shows up here for free.
    func reference() -> ReferenceDTO {
        ReferenceDTO(
            accountTypes: AccountType.allCases.map {
                AccountTypeRefDTO(
                    value: $0.rawValue,
                    displayName: $0.displayName,
                    description: $0.description,
                    icon: $0.icon,
                    hasBehavior: $0.hasBehavior,
                    isUnique: $0.isUnique
                )
            },
            frequencies: Frequency.allCases.map {
                FrequencyRefDTO(value: $0.rawValue, displayName: $0.displayName, icon: $0.icon)
            },
            allocationModes: AllocationMode.allCases.map {
                DescribedRefDTO(
                    value: $0.rawValue,
                    displayName: $0.displayName,
                    description: $0.description
                )
            },
            savingsInputModes: SavingsInputMode.allCases.map {
                SimpleRefDTO(value: $0.rawValue, displayName: $0.displayName)
            },
            remainingMoneyDestinations: RemainingMoneyDestination.allCases.map {
                DestinationRefDTO(
                    value: $0.rawValue,
                    displayName: $0.displayName,
                    description: $0.description,
                    icon: destinationIcon(for: $0)
                )
            },
            currencies: Currency.allCases.map {
                CurrencyRefDTO(value: $0.rawValue, symbol: $0.symbol, displayName: $0.displayName)
            },
            savingsConstants: SavingsConstantsDTO(
                minimumPercentage: SavingsAllocationEntry.minimumPercentage,
                maximumPercentage: SavingsAllocationEntry.maximumPercentage,
                recommendedPercentage: SavingsAllocationEntry.recommendedPercentage,
                presets: SavingsAllocationEntry.presets,
                defaultBoostMultiplier: SavingsAllocationEntry().boostMultiplier,
                defaultEmergencyMultiplier: Defaults.emergencyMultiplier,
                step: PickerAssembler.sliderStep,
                snapThreshold: PickerAssembler.snapThreshold,
                accessibilityStep: PickerAssembler.accessibilityStep,
                snapValues: PickerAssembler.snapValues,
                greatRateRange: [
                    PickerAssembler.greatRateRange.low, PickerAssembler.greatRateRange.high
                ]
            ),
            expenseIcons: Defaults.expenseIcons,
            categoryIcons: Defaults.categoryIcons,
            categoryColors: Defaults.categoryColors,
            defaultNewCategory: DefaultCategoryDTO(
                icon: Defaults.newCategoryIcon,
                colorHex: Defaults.newCategoryColorHex,
                sortOrder: Defaults.newCategorySortOrder
            ),
            defaultExpenseIcon: Defaults.expenseIcon,
            // Unresolved (no income in scope here); resolved per account in `multiplierOptions`.
            emergencyMultiplierOptions: pickers.multiplierOptions(
                selected: Defaults.emergencyMultiplier,
                hardCap: nil,
                monthlyIncome: 0,
                money: MoneyFormatter(currencyCode: "RON")
            ),
            accountSuggestions: Defaults.accountSuggestions.map {
                AccountSuggestionDTO(
                    title: $0.title,
                    accountType: $0.type.rawValue,
                    icon: $0.type.icon
                )
            }
        )
    }

    /// Declared outside Domain, in `Onboarding/Components/RemainingMoneyPicker.swift:77-85`.
    private func destinationIcon(for destination: RemainingMoneyDestination) -> String {
        switch destination {
        case .primarySavings: AccountType.savings.icon
        case .personal: AccountType.personal.icon
        case .primary: AccountType.primary.icon
        }
    }
}
