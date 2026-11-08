import Domain
import Foundation
import Utilities
import Vapor

/// Holds the store + assembler for the request handlers.
public struct AppContext: Sendable {
    public let store: JSONStore
    public let assembler: StateAssembler

    public init(store: JSONStore, assembler: StateAssembler = StateAssembler()) {
        self.store = store
        self.assembler = assembler
    }

    /// The current state, freshly derived.
    public func state(now: Date = Date()) async throws -> AppStateResponse {
        assembler.assemble(try await store.load(), now: now)
    }

    /// Mutate, then return the **whole** freshly-derived state.
    ///
    /// This is the iOS data-flow contract (`DOMAIN-CONTRACT.md §8`): a single `DataObserver`
    /// listens for `ModelContext.didSave` and re-runs `refreshAllData()`, so any save re-derives
    /// every view model. Returning full state from every mutation reproduces that exactly and
    /// makes the client trivially consistent — it replaces its store rather than patching it.
    public func mutating(
        now: Date = Date(),
        _ body: @Sendable (inout StoreDocument) throws -> Void
    ) async throws -> AppStateResponse {
        let (document, _) = try await store.mutate { try body(&$0) }
        return assembler.assemble(document, now: now)
    }
}

public func registerRoutes(_ app: Application, context: AppContext) throws {
    let api = app.grouped("api")

    // MARK: - State

    api.get("state") { request in try await context.state(now: request.diamerisNow) }

    api.get("transfer-plan") { _ -> TransferPlanResponse in
        TransferPlanResponse(transferPlan: try await context.state().transferPlan)
    }

    api.get("categories") { _ -> CategoriesResponse in
        CategoriesResponse(categories: try await context.state().categories)
    }

    // MARK: - Onboarding

    api.post("onboarding", "complete") { request -> AppStateResponse in
        let payload = try request.content.decode(OnboardingPayload.self)
        return try await context.mutating { document in
            OnboardingService.apply(payload, to: &document)
        }
    }

    api.post("onboarding", "preview") { request -> OnboardingPreviewResponse in
        let payload = try request.content.decode(OnboardingPayload.self)
        return OnboardingService.preview(payload, assembler: context.assembler)
    }

    // MARK: - Settings

    api.put("settings") { request -> AppStateResponse in
        let payload = try request.content.decode(SettingsUpdatePayload.self)
        return try await context.mutating { document in
            if let name = payload.name {
                document.profile?.name = name
            }
            if let currencyCode = payload.currencyCode {
                document.profile?.currencyCode = currencyCode
            }
            if let destination = payload.remainingMoneyDestination {
                document.profile?.remainingMoneyDestination = destination
            }
            if let income = payload.monthlyIncome {
                if document.income == nil {
                    document.income = IncomeRecord(amount: income.value)
                } else {
                    document.income?.amount = income
                }
            }
            payload.savings?.apply(to: &document.savings)
        }
    }

    // MARK: - Accounts

    api.get("accounts") { _ -> [AccountDTO] in
        try await context.state().accounts
    }

    api.post("accounts") { request -> AppStateResponse in
        let payload = try request.content.decode(AccountCreatePayload.self)
        return try await context.mutating { document in
            let type = payload.accountType ?? .other

            // `AccountType.isUnique` — the app allows at most one emergency account.
            if type.isUnique, document.accounts.contains(where: { $0.accountType == type }) {
                throw Abort(.conflict, reason: "Only one \(type.rawValue) account is allowed")
            }

            let makePrimary = payload.isPrimary ?? false
            if makePrimary {
                for index in document.accounts.indices {
                    document.accounts[index].isPrimary = false
                }
            }

            let sortOrder = (document.accounts.map(\.sortOrder).max() ?? -1) + 1
            document.accounts.append(
                AccountRecord(
                    id: payload.id ?? UUID(),
                    name: payload.name,
                    purpose: payload.purpose,
                    accountType: type,
                    isPrimary: makePrimary,
                    isPrimarySavings: payload.isPrimarySavings ?? false,
                    emergencyMultiplier: payload.emergencyMultiplier,
                    emergencyHardCap: payload.emergencyHardCap?.value,
                    currentBalance: payload.currentBalance?.value ?? 0,
                    sortOrder: sortOrder
                )
            )
        }
    }

    api.put("accounts", ":id") { request -> AppStateResponse in
        let id = try request.requireUUID("id")
        let payload = try request.content.decode(AccountUpdatePayload.self)
        return try await context.mutating { document in
            guard let index = document.accounts.firstIndex(where: { $0.id == id }) else {
                throw Abort(.notFound, reason: "No account with id \(id)")
            }

            if let type = payload.accountType, type.isUnique {
                let clash = document.accounts.contains { $0.id != id && $0.accountType == type }
                if clash {
                    throw Abort(.conflict, reason: "Only one \(type.rawValue) account is allowed")
                }
            }

            if payload.isPrimary == true {
                for other in document.accounts.indices {
                    document.accounts[other].isPrimary = false
                }
            }

            if let name = payload.name { document.accounts[index].name = name }
            if let purpose = payload.purpose { document.accounts[index].purpose = purpose }
            if let type = payload.accountType { document.accounts[index].accountType = type }
            if let isPrimary = payload.isPrimary { document.accounts[index].isPrimary = isPrimary }
            if let flag = payload.isPrimarySavings { document.accounts[index].isPrimarySavings = flag }
            if let multiplier = payload.emergencyMultiplier {
                document.accounts[index].emergencyMultiplier = multiplier
            }
            if let cap = payload.emergencyHardCap { document.accounts[index].emergencyHardCap = cap }
            if let balance = payload.currentBalance { document.accounts[index].currentBalance = balance }
            if let sortOrder = payload.sortOrder { document.accounts[index].sortOrder = sortOrder }
        }
    }

    api.delete("accounts", ":id") { request -> AppStateResponse in
        let id = try request.requireUUID("id")
        return try await context.mutating { document in
            guard let index = document.accounts.firstIndex(where: { $0.id == id }) else {
                throw Abort(.notFound, reason: "No account with id \(id)")
            }
            if document.accounts[index].isPrimary {
                throw Abort(.conflict, reason: "The primary account cannot be removed")
            }
            document.accounts.remove(at: index)
        }
    }

    // MARK: - Expenses

    api.get("expenses") { _ -> [ExpenseDTO] in
        try await context.state().expenses
    }

    api.post("expenses") { request -> AppStateResponse in
        let payload = try request.content.decode(ExpenseCreatePayload.self)
        return try await context.mutating { document in
            let sortOrder = (document.expenses.map(\.sortOrder).max() ?? -1) + 1
            document.expenses.append(
                ExpenseRecord(
                    name: payload.name,
                    amount: payload.amount.value,
                    frequency: payload.frequency ?? .monthly,
                    icon: payload.icon ?? Defaults.expenseIcon,
                    isEnabled: payload.isEnabled ?? true,
                    linkedAccountId: payload.linkedAccountId,
                    categoryId: payload.categoryId,
                    notes: payload.notes,
                    sortOrder: sortOrder
                )
            )
        }
    }

    api.put("expenses", ":id") { request -> AppStateResponse in
        let id = try request.requireUUID("id")
        let payload = try request.content.decode(ExpenseUpdatePayload.self)
        return try await context.mutating { document in
            guard let index = document.expenses.firstIndex(where: { $0.id == id }) else {
                throw Abort(.notFound, reason: "No expense with id \(id)")
            }
            if let name = payload.name { document.expenses[index].name = name }
            if let amount = payload.amount { document.expenses[index].amount = amount }
            if let frequency = payload.frequency { document.expenses[index].frequency = frequency }
            if let icon = payload.icon { document.expenses[index].icon = icon }
            if let isEnabled = payload.isEnabled { document.expenses[index].isEnabled = isEnabled }
            if let notes = payload.notes { document.expenses[index].notes = notes }
            if let sortOrder = payload.sortOrder { document.expenses[index].sortOrder = sortOrder }

            // An explicit `null` clears; an absent key leaves it alone.
            if payload.clearsCategory {
                document.expenses[index].categoryId = nil
            } else if let categoryId = payload.categoryId {
                document.expenses[index].categoryId = categoryId
            }
            if payload.clearsLinkedAccount {
                document.expenses[index].linkedAccountId = nil
            } else if let accountId = payload.linkedAccountId {
                document.expenses[index].linkedAccountId = accountId
            }
        }
    }

    /// Live values for an **unsaved** draft in the Add/Edit Expense sheet. Persists nothing.
    ///
    /// R18 granted a narrow exception letting the client do this one multiply locally, but the
    /// exception was written as `× 12` when the real operation is `× (1/12)` — so taking it would
    /// have shipped a value 144× off. Serving it keeps the single implementation and the half-even
    /// rounding. Debounce it like `/onboarding/preview`.
    api.post("expenses", "preview") { request -> ExpensePreviewResponse in
        let payload = try request.content.decode(ExpensePreviewPayload.self)
        let document = try await context.store.load()
        let money = MoneyFormatter(currency: document.currency)
        let frequency = payload.frequency ?? .monthly

        // Straight through Domain — no arithmetic here.
        let entry = ExpenseEntry(
            name: "",
            amount: payload.amount.value,
            frequency: frequency,
            icon: Defaults.expenseIcon
        )

        return ExpensePreviewResponse(
            amount: money(entry.amount),
            monthlyAmount: money(entry.monthlyAmount),
            annualAmount: money(entry.annualAmount),
            monthlyEquivalent: money(entry.monthlyAmount),
            showsMonthlyEquivalent: frequency == .annual && entry.amount > 0
        )
    }

    api.delete("expenses", ":id") { request -> AppStateResponse in
        let id = try request.requireUUID("id")
        return try await context.mutating { document in
            guard let index = document.expenses.firstIndex(where: { $0.id == id }) else {
                throw Abort(.notFound, reason: "No expense with id \(id)")
            }
            document.expenses.remove(at: index)
        }
    }

    // MARK: - Categories

    api.post("categories") { request -> AppStateResponse in
        let payload = try request.content.decode(CategoryCreatePayload.self)
        return try await context.mutating { document in
            document.categories.append(
                CategoryRecord(
                    id: payload.id ?? UUID(),
                    name: payload.name,
                    icon: payload.icon,
                    colorHex: payload.colorHex,
                    isDefault: false,
                    sortOrder: payload.sortOrder ?? Defaults.newCategorySortOrder
                )
            )
        }
    }

    api.put("categories", ":id") { request -> AppStateResponse in
        let id = try request.requireUUID("id")
        let payload = try request.content.decode(CategoryUpdatePayload.self)
        return try await context.mutating { document in
            guard let index = document.categories.firstIndex(where: { $0.id == id }) else {
                throw Abort(.notFound, reason: "No category with id \(id)")
            }
            if document.categories[index].isDefault {
                throw Abort(.conflict, reason: "Default categories cannot be edited")
            }
            if let name = payload.name { document.categories[index].name = name }
            if let icon = payload.icon { document.categories[index].icon = icon }
            if let colorHex = payload.colorHex { document.categories[index].colorHex = colorHex }
            if let sortOrder = payload.sortOrder { document.categories[index].sortOrder = sortOrder }
        }
    }

    api.delete("categories", ":id") { request -> AppStateResponse in
        let id = try request.requireUUID("id")
        return try await context.mutating { document in
            guard let index = document.categories.firstIndex(where: { $0.id == id }) else {
                throw Abort(.notFound, reason: "No category with id \(id)")
            }
            if document.categories[index].isDefault {
                throw Abort(.conflict, reason: "Default categories cannot be deleted")
            }
            // Expenses keep their now-dangling categoryId, exactly as iOS does — the Expenses
            // feature is built to tolerate unknown category ids.
            document.categories.remove(at: index)
        }
    }

    // MARK: - New Month

    api.post("new-month", "preview") { request -> NewMonthPreviewResponse in
        let payload = try request.content.decode(NewMonthPayload.self)
        let document = try await context.store.load()
        return NewMonthService.preview(payload, document: document, assembler: context.assembler)
    }

    api.post("new-month") { request -> AppStateResponse in
        let payload = try request.content.decode(NewMonthPayload.self)
        return try await context.mutating { document in
            NewMonthService.commit(payload, to: &document)
        }
    }

    // MARK: - Test oracle (Reviewer's golden-vectors harness)

    /// Computes a scenario's outputs without persisting anything, keyed with the exact names
    /// `Web/Docs/golden-vectors.json` uses in `expected`. Exists so the fixture is not coupled to
    /// the onboarding payload shape and does not need a reset→onboard→new-month dance per case.
    api.post("golden", "seed") { request -> GoldenResultResponse in
        let payload = try request.content.decode(GoldenScenarioPayload.self)
        return GoldenService.evaluate(payload, assembler: context.assembler)
    }

    // MARK: - Dev tools

    api.post("reset") { _ -> AppStateResponse in
        let document = try await context.store.reset()
        return context.assembler.assemble(document)
    }

    /// Exposes `Utilities.AmountFormatter.parse` so the client never reimplements input parsing.
    /// ⚠️ Reproduces the upstream iOS quirk: *all* commas become periods, so `"1,234"` parses
    /// as `1.234`. Deliberate, for parity (`DECISIONS.md` D1).
    api.post("parse-amount") { request -> Money in
        let payload = try request.content.decode(ParseAmountPayload.self)
        let document = try await context.store.load()
        return Money(AmountFormatter.parse(payload.text), currency: document.currency.rawValue)
    }
}

extension Request {
    /// R17: the parity harness sends `X-Diameris-Now` so the Dashboard's month title is
    /// deterministic instead of depending on the machine clock (which would flake at month
    /// boundaries). Absent or unparseable → real time.
    var diamerisNow: Date {
        guard let raw = headers.first(name: "X-Diameris-Now") else { return Date() }
        // Built per call: ISO8601DateFormatter is not Sendable, so a shared static would be a
        // data race across concurrent requests.
        let withMillis = ISO8601DateFormatter()
        withMillis.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return withMillis.date(from: raw) ?? ISO8601DateFormatter().date(from: raw) ?? Date()
    }

    func requireUUID(_ name: String) throws -> UUID {
        guard let raw = parameters.get(name), let id = UUID(uuidString: raw) else {
            throw Abort(.badRequest, reason: "'\(name)' must be a UUID")
        }
        return id
    }
}
