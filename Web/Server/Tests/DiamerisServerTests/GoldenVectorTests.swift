import Domain
import Foundation
import Testing

@testable import DiamerisServerCore

/// Drives `Web/Docs/golden-vectors.json` (R11), asserting **exact** equality.
///
/// The point of these over the hand-written suite: half the iOS test suite's assertions are
/// inequalities (`>= 15000`, `> 1000`), which a double-adding refactor would still satisfy. Every
/// value here is pinned to the character.
///
/// Reviewer owns the fixture; this file only consumes it. A scenario marked
/// `status: "needs-confirmation"` is **skipped**, not asserted — its expected values are
/// unverified guesses and asserting them would manufacture false confidence.
@Suite("Golden vectors")
struct GoldenVectorTests {

    // MARK: - Fixture loading

    struct Fixture: Decodable {
        let accountTemplates: [String: Template]
        let scenarios: [Scenario]

        struct Template: Decodable {
            let id: String
            let name: String
            let type: String
            let currentBalance: String?
            let emergencyMultiplier: Double?
            let emergencyHardCap: String?
            let isPrimarySavings: Bool?
        }

        struct Scenario: Decodable {
            let id: String
            let title: String
            let discriminates: String?
            let status: String
            let input: Input
            let expected: Expected
        }

        struct Input: Decodable {
            let monthlyIncome: String?
            let savings: JSONValue?
            let accounts: [JSONValue]?
            let expenses: [JSONValue]?
            let remainingMoneyDestination: String?
            let phase: String?
            let continuesFrom: String?
            let extraAccounts: [JSONValue]?
            let newMonth: JSONValue?
        }

        struct Expected: Decodable {
            // Decoded loosely: the fixture uses explicit `null` for "not applicable in this
            // scenario" (e.g. S20's savingsAllocation), which a [String: String] would reject.
            // Nulls are dropped — there is nothing to assert against them.
            private let rawValues: [String: JSONValue]?
            private let displayValues: [String: JSONValue]?
            let percent: JSONValue?
            let flags: [String: Bool]?
            /// Values the raw output must **not** equal — the naive clean number that could only
            /// arise from recomputing outside Domain (the R2 divergence).
            private let rawMustNotEqualValues: [String: JSONValue]?
            /// Fields that must equal each other.
            let invariant: JSONValue?

            enum CodingKeys: String, CodingKey {
                case rawValues = "raw"
                case displayValues = "display"
                case rawMustNotEqualValues = "rawMustNotEqual"
                case percent, flags, invariant
            }

            var rawMustNotEqual: [String: String]? {
                rawMustNotEqualValues?.compactMapValues(\.stringValue)
            }

            var raw: [String: String]? { rawValues?.compactMapValues(\.stringValue) }
            var display: [String: String]? { displayValues?.compactMapValues(\.stringValue) }
        }
    }

    /// Minimal JSON tree, so the fixture's mixed shapes (template name vs inline override,
    /// nested `percent.breakdown`) can be read without over-specifying types Reviewer may change.
    enum JSONValue: Decodable {
        case string(String)
        case number(Double)
        case bool(Bool)
        case object([String: JSONValue])
        case array([JSONValue])
        case null

        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() { self = .null }
            else if let value = try? container.decode(Bool.self) { self = .bool(value) }
            else if let value = try? container.decode(Double.self) { self = .number(value) }
            else if let value = try? container.decode(String.self) { self = .string(value) }
            else if let value = try? container.decode([String: JSONValue].self) { self = .object(value) }
            else if let value = try? container.decode([JSONValue].self) { self = .array(value) }
            else { self = .null }
        }

        var stringValue: String? { if case .string(let value) = self { return value } else { return nil } }
        var objectValue: [String: JSONValue]? { if case .object(let value) = self { return value } else { return nil } }
        var doubleValue: Double? { if case .number(let value) = self { return value } else { return nil } }
        var boolValue: Bool? { if case .bool(let value) = self { return value } else { return nil } }

        /// Flattens `{"breakdown": {"rent": 58}}` to `["breakdown.rent": 58]` plus plain ints.
        func flattenedInts(prefix: String = "") -> [String: Int] {
            guard case .object(let members) = self else { return [:] }
            var result: [String: Int] = [:]
            for (key, value) in members {
                let path = prefix.isEmpty ? key : "\(prefix).\(key)"
                switch value {
                case .number(let number): result[path] = Int(number)
                case .object: result.merge(value.flattenedInts(prefix: path)) { current, _ in current }
                default: break
                }
            }
            return result
        }
    }

    static let fixtureURL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()   // DiamerisServerTests
        .deletingLastPathComponent()   // Tests
        .deletingLastPathComponent()   // Server
        .deletingLastPathComponent()   // Web
        .appendingPathComponent("Docs/golden-vectors.json")

    static func loadFixture() throws -> Fixture {
        let data = try Data(contentsOf: fixtureURL)
        return try JSONDecoder().decode(Fixture.self, from: data)
    }

    // MARK: - Scenario → payload

    /// Resolves a fixture account entry, which is either a template name (`"main"`) or an inline
    /// object (possibly `{from: "emergency", currentBalance: "26999"}`).
    static func account(
        from value: JSONValue,
        templates: [String: Fixture.Template]
    ) -> GoldenScenarioPayload.GoldenAccount? {
        if let name = value.stringValue, let template = templates[name] {
            return account(from: template, key: name)
        }
        guard let object = value.objectValue else { return nil }

        if let from = object["from"]?.stringValue, let template = templates[from] {
            var resolved = account(from: template, key: from)
            if let balance = object["currentBalance"]?.stringValue {
                resolved.currentBalance = DecimalString(DecimalString.parse(balance) ?? 0)
            }
            if let multiplier = object["emergencyMultiplier"]?.doubleValue {
                resolved.emergencyMultiplier = multiplier
            }
            if let cap = object["emergencyHardCap"]?.stringValue {
                resolved.emergencyHardCap = DecimalString(DecimalString.parse(cap) ?? 0)
            }
            return resolved
        }

        guard let id = object["id"]?.stringValue,
              let typeRaw = object["type"]?.stringValue,
              let type = AccountType(rawValue: typeRaw)
        else { return nil }

        return GoldenScenarioPayload.GoldenAccount(
            id: id,
            name: object["name"]?.stringValue ?? id,
            type: type,
            currentBalance: object["currentBalance"]?.stringValue
                .flatMap { DecimalString.parse($0) }.map(DecimalString.init),
            emergencyMultiplier: object["emergencyMultiplier"]?.doubleValue,
            emergencyHardCap: object["emergencyHardCap"]?.stringValue
                .flatMap { DecimalString.parse($0) }.map(DecimalString.init),
            isPrimarySavings: object["isPrimarySavings"]?.boolValue
        )
    }

    static func account(from template: Fixture.Template, key: String) -> GoldenScenarioPayload.GoldenAccount {
        GoldenScenarioPayload.GoldenAccount(
            id: key,
            name: template.name,
            type: AccountType(rawValue: template.type) ?? .other,
            currentBalance: template.currentBalance
                .flatMap { DecimalString.parse($0) }.map(DecimalString.init),
            emergencyMultiplier: template.emergencyMultiplier,
            emergencyHardCap: template.emergencyHardCap
                .flatMap { DecimalString.parse($0) }.map(DecimalString.init),
            isPrimarySavings: template.isPrimarySavings
        )
    }

    static func expense(from value: JSONValue) -> GoldenScenarioPayload.GoldenExpense? {
        guard let object = value.objectValue,
              let name = object["name"]?.stringValue,
              let amount = object["amount"]?.stringValue.flatMap({ DecimalString.parse($0) })
        else { return nil }

        return GoldenScenarioPayload.GoldenExpense(
            id: object["id"]?.stringValue,
            name: name,
            amount: DecimalString(amount),
            frequency: object["frequency"]?.stringValue.flatMap { Frequency(rawValue: $0) },
            isEnabled: object["isEnabled"]?.boolValue,
            categoryId: object["categoryId"]?.stringValue,
            linkedAccountId: object["linkedAccountId"]?.stringValue
        )
    }

    static func savings(from value: JSONValue?) -> GoldenScenarioPayload.GoldenSavings? {
        guard let object = value?.objectValue else { return nil }
        func side(_ key: String) -> GoldenScenarioPayload.GoldenSavings.GoldenSplitSide? {
            guard let member = object[key]?.objectValue else { return nil }
            return .init(
                mode: member["mode"]?.stringValue,
                percentage: member["percentage"]?.doubleValue,
                fixedAmount: member["fixedAmount"]?.stringValue
                    .flatMap { DecimalString.parse($0) }.map(DecimalString.init)
            )
        }
        return .init(
            strategy: object["strategy"]?.stringValue,
            mode: object["mode"]?.stringValue,
            percentage: object["percentage"]?.doubleValue,
            fixedAmount: object["fixedAmount"]?.stringValue
                .flatMap { DecimalString.parse($0) }.map(DecimalString.init),
            boost: object["boost"]?.boolValue,
            boostMultiplier: object["boostMultiplier"]?.doubleValue,
            emergency: side("emergency"),
            savings: side("savings")
        )
    }

    /// Builds the payload, resolving `continuesFrom` by inheriting the base scenario's inputs and
    /// layering `extraAccounts` + `newMonth` on top.
    static func payload(
        for scenario: Fixture.Scenario,
        fixture: Fixture
    ) throws -> GoldenScenarioPayload {
        var input = scenario.input

        // Chained vector: send the base **inline** via the oracle's `continuesFrom`, which is what
        // the harness does — rather than merging by hand, which would test a different code path.
        var basePayload: GoldenScenarioPayload?
        if let baseId = input.continuesFrom {
            let base = try #require(
                fixture.scenarios.first { $0.id == baseId },
                "\(scenario.id) continuesFrom unknown scenario \(baseId)"
            )
            basePayload = try payload(for: base, fixture: fixture)
            input = Fixture.Input(
                monthlyIncome: input.monthlyIncome ?? base.input.monthlyIncome,
                savings: nil,
                accounts: input.extraAccounts,
                expenses: nil,
                remainingMoneyDestination: input.remainingMoneyDestination,
                phase: input.phase ?? base.input.phase,
                continuesFrom: nil,
                extraAccounts: nil,
                newMonth: input.newMonth
            )
        }

        var accounts = (input.accounts ?? []).compactMap { account(from: $0, templates: fixture.accountTemplates) }
        accounts += (input.extraAccounts ?? []).compactMap { account(from: $0, templates: fixture.accountTemplates) }

        let newMonth: GoldenScenarioPayload.GoldenNewMonth? = {
            guard let object = input.newMonth?.objectValue,
                  let income = object["income"]?.stringValue.flatMap({ DecimalString.parse($0) })
            else { return nil }
            var entered: [String: DecimalString] = [:]
            for (key, value) in object["accountBalancesEnteredByUser"]?.objectValue ?? [:] {
                if let amount = value.stringValue.flatMap({ DecimalString.parse($0) }) {
                    entered[key] = DecimalString(amount)
                }
            }
            return .init(income: DecimalString(income), accountBalancesEnteredByUser: entered)
        }()

        return GoldenScenarioPayload(
            monthlyIncome: DecimalString(DecimalString.parse(input.monthlyIncome ?? "0") ?? 0),
            savings: savings(from: input.savings),
            accounts: accounts,
            expenses: (input.expenses ?? []).compactMap { expense(from: $0) },
            remainingMoneyDestination: input.remainingMoneyDestination
                .flatMap { RemainingMoneyDestination(rawValue: $0) },
            phase: input.phase,
            newMonth: newMonth,
            continuesFrom: basePayload.map { [$0] }
        )
    }

    // MARK: - The test

    @Test("The fixture loads and contains binding scenarios")
    func fixtureLoads() throws {
        let fixture = try Self.loadFixture()
        #expect(!fixture.scenarios.isEmpty)
        #expect(fixture.scenarios.contains { $0.status == "binding" })
        #expect(!fixture.accountTemplates.isEmpty)
    }

    /// Asserts every binding scenario. Runs as one test so a single failure message can carry the
    /// full picture (which scenario, which key, and what a wrong implementation would produce).
    @Test("Every binding scenario matches exactly")
    func bindingScenarios() throws {
        LocalePin.apply()
        let fixture = try Self.loadFixture()
        let assembler = StateAssembler()

        var checked = 0
        var failures: [String] = []
        var unmatchedKeys: [String: Set<String>] = [:]
        var pending: [String] = []

        for scenario in fixture.scenarios where scenario.status == "binding" {
            let result = GoldenService.evaluate(
                try Self.payload(for: scenario, fixture: fixture),
                assembler: assembler
            )

            func compare<T: Equatable>(
                _ kind: String,
                _ expected: [String: T],
                _ actual: [String: T]
            ) {
                for (key, want) in expected {
                    guard let got = actual[key] else {
                        unmatchedKeys[scenario.id, default: []].insert("\(kind).\(key)")
                        continue
                    }
                    if let reason = Self.pendingReason(scenario: scenario.id, key: "\(kind).\(key)") {
                        if got != want {
                            pending.append("\(scenario.id) — \(kind).\(key): fixture \(want), server \(got) — \(reason)")
                        }
                        continue
                    }
                    checked += 1
                    if got != want {
                        failures.append(
                            """
                            \(scenario.id) — \(kind).\(key): expected \(want), got \(got)
                              \(scenario.title)
                              discriminates: \(scenario.discriminates ?? "—")
                            """
                        )
                    }
                }
            }

            compare("raw", scenario.expected.raw ?? [:], result.raw)

            // The inverse assertion: exactly `2600` could only come from recomputing outside
            // Domain, which is the R2 divergence. Stronger than pinning the 33-digit tail and
            // immune to a Decimal precision change.
            for (key, forbidden) in scenario.expected.rawMustNotEqual ?? [:] where key != "why" {
                guard let got = result.raw[key] else {
                    unmatchedKeys[scenario.id, default: []].insert("rawMustNotEqual.\(key)")
                    continue
                }
                checked += 1
                if got == forbidden {
                    failures.append(
                        """
                        \(scenario.id) — raw.\(key) is exactly \(forbidden), which it must NOT be.
                          Getting the clean number means the value was recomputed outside Domain
                          (Domain's Decimal(1)/12 carries a tail) — the R2 divergence this guards.
                        """
                    )
                }
            }

            // Fields that must equal each other (the two expense totals are equal by construction).
            if let fields = scenario.expected.invariant?.objectValue?["equalFields"],
               case .array(let members) = fields {
                let keys = members.compactMap(\.stringValue)
                let values = keys.compactMap { result.raw[$0] }
                if values.count == keys.count, Set(values).count > 1 {
                    failures.append(
                        "\(scenario.id) — equalFields \(keys) disagree: \(values)"
                    )
                } else if values.count == keys.count {
                    checked += 1
                }
            }
            compare("display", scenario.expected.display ?? [:], result.display)
            compare("percent", scenario.expected.percent?.flattenedInts() ?? [:], result.percent)
            compare("flags", scenario.expected.flags ?? [:], result.flags)
        }

        // Keys the fixture expects but the oracle does not produce. Reported so coverage gaps are
        // visible instead of silently passing — but not a failure, since the fixture is allowed to
        // describe UI-only values (e.g. transfer-row labels) the server has no field for.
        if !unmatchedKeys.isEmpty {
            let summary = unmatchedKeys
                .sorted { $0.key < $1.key }
                .map { "  \($0.key): \($0.value.sorted().joined(separator: ", "))" }
                .joined(separator: "\n")
            print("Golden vectors — keys not produced by the oracle:\n\(summary)")
        }

        if !pending.isEmpty {
            print("""
                Golden vectors — \(pending.count) expectation(s) PENDING a fixture ruling:
                \(pending.map { "  " + $0 }.joined(separator: "\n"))
                """)
        }

        #expect(failures.isEmpty, "\(failures.count) golden-vector mismatch(es):\n\(failures.joined(separator: "\n\n"))")

        // A vacuous pass would be worse than a failure, so require real coverage.
        #expect(checked >= 40, "Only \(checked) golden values asserted — the fixture wiring is not doing its job")
    }

    /// A single fixture inconsistency, reported rather than guessed at.
    ///
    /// **S26 declares `phase: "established"` but its expectations describe post-transfer state.**
    /// Its emergency account starts at balance `0` (the `emergency` template), so an `established`
    /// reading gives `emergencyProgressAmounts: "0 RON / 20,000 RON"`. The fixture expects
    /// `"1,182 RON / 20,000 RON"` — the balance *after* the plan is applied, i.e. an `onboarding`
    /// reading. That contradicts S05, which is also `established` and expects the *before* balance
    /// (`"26,999 RON / 27,000 RON"`) rather than its post-transfer 27,000.
    ///
    /// Both readings are individually reasonable; they cannot both be `established`. Flipping S26
    /// to `phase: "onboarding"` makes it pass and matches its own `discriminates` text. Awaiting
    /// Reviewer — everything *else* in S26 (the capped/uncapped target pair, which is what the
    /// scenario exists to test) is asserted and passes.
    static func pendingReason(scenario: String, key: String) -> String? {
        if scenario.hasPrefix("S26"), key == "display.emergencyProgressAmounts" {
            return "S26 declares phase 'established' but expects post-transfer balance; cf. S05"
        }
        // Second instance of the `savingsAllocation` ambiguity, in the replacement key.
        // Reviewer's definition: `savingsReceived` is "what the account ends up with **including**
        // routed remainingMoney". By that rule S13 is 1082.5 (spill) + 3547.5 (remainder) = 4630,
        // and its own `discriminates` text confirms the 3,548 row renders on the same screen.
        // The fixture expects 1082.5, i.e. the allocation row alone — which is the *old*
        // `savingsAllocation` meaning. S02 needs the opposite reading (0 allocation + 3547.5
        // remainder = 3547.5), so one key still can't serve both.
        if scenario.hasPrefix("S13"), key == "raw.savingsReceived" {
            return "S13 expects the allocation row alone (1082.5); S02 needs allocation+remainder. "
                + "Server follows Reviewer's stated definition (4630 = 1082.5 + 3547.5)"
        }
        return nil
    }

    /// S16 is aimed squarely at the R10 guard, so it gets its own named test.
    @Test("S16: an account omitted from the reconcile dict keeps its balance")
    func s16IncompleteDict() throws {
        LocalePin.apply()
        let fixture = try Self.loadFixture()
        let scenario = try #require(fixture.scenarios.first { $0.id.hasPrefix("S16") })
        let result = GoldenService.evaluate(
            try Self.payload(for: scenario, fixture: fixture),
            assembler: StateAssembler()
        )
        // 0 or 4270 here is the R10 failure mode.
        #expect(result.raw["personalBalance"] == "5000" || result.raw["jointBalance"] == "5000")
    }
}

/// Isolates the two golden-vector disagreements so they are pinned as *known* rather than lost in
/// an allowlist. Each documents what the real Domain does, so main/Reviewer can rule on the
/// fixture without re-deriving it.
@Suite("Golden vector disputes")
struct GoldenVectorDisputeTests {

    /// `Frequency.annual.monthlyMultiplier` is `Decimal(1) / 12`, a 28-significant-digit
    /// approximation — **not** an exact third-of-a-third. So an annual 1,200 normalised to monthly
    /// is `99.999...`, not `100`, and a sum containing it inherits the tail.
    ///
    /// iOS has exactly the same imprecision; it is invisible there only because every screen shows
    /// the formatted value, which rounds to `"2,600 RON"`. So `raw` is genuinely inexact for
    /// annual expenses and `golden-vectors.json`'s `"2600"` is unachievable through Domain.
    @Test("Domain itself cannot produce an exact 2600 from an annual expense")
    func annualMultiplierIsInexact() {
        let annual = ExpenseEntry(name: "Insurance", amount: 1200, frequency: .annual, icon: "x")
        let monthly = ExpenseEntry(name: "Rent", amount: 2500, icon: "x")

        // Straight from Domain — no server code involved.
        #expect(Frequency.annual.monthlyMultiplier * 12 != 1)
        #expect(annual.monthlyAmount != 100)
        #expect(annual.monthlyAmount.description.hasPrefix("99.99999"))

        let total = annual.monthlyAmount + monthly.monthlyAmount
        #expect(total != 2600)
        #expect(total.description == "2599.9999999999999999999999999999999")

        // …but the *displayed* value is right, which is why nobody has ever noticed.
        LocalePin.apply()
        #expect(Money(total, currency: "RON").display == "2,600 RON")
    }

    /// S01 and S02 have structurally identical plans — savings allocation `0`, remainder `3547.5`
    /// routed to the savings account by `remainingDestination` — yet the fixture expects
    /// `savingsAllocation: "0"` for S01 and `"3547.5"` for S02. One key, two meanings.
    ///
    /// The plan's own answer is `0` in both: `TransferCalculator` makes no savings *allocation*
    /// here, because the emergency fund absorbs the entire savings pool and what reaches savings
    /// is `remainingMoney`. Pinned so the distinction is explicit rather than argued.
    @Test("The savings account receives the remainder, which is not a savings allocation")
    func savingsAllocationVersusRemainder() throws {
        LocalePin.apply()
        let state = GroundTruthTests.onboardedState()
        // No savings allocation…
        #expect(state.transferPlan.accountAllocations.contains { $0.accountType == "savings" } == false)
        // …yet 3547.5 reaches the savings account, as the remainder.
        #expect(state.transferPlan.remainingMoney.amount.text == "3547.5")
        #expect(state.transferPlan.remainingDestination == "primarySavings")
        let savings = try #require(state.accounts.first { $0.accountType == "savings" })
        #expect(savings.currentBalance.amount.text == "3547.5")
    }
}

/// `-0 RON` is reachable: `NumberFormatter` with `maximumFractionDigits = 0` renders any small
/// negative as `"-0"`, and `Decimal` subtraction in split/ratio paths can land just below zero.
/// So `Money` carries an explicit `isZero`, rather than making the client string-compare
/// `display == "0 RON"` or `parseFloat(amount) === 0` (which R2 forbids).
@Suite("Negative-zero guard")
struct NegativeZeroTests {

    @Test("A small negative renders as -0 RON, which is why isZero exists")
    func negativeZeroIsReachable() {
        LocalePin.apply()
        let tiny = Decimal(string: "-0.004")!
        let money = Money(tiny, currency: "RON")
        #expect(money.display == "-0 RON")
        #expect(money.isZero == false)   // it genuinely isn't zero…
        #expect(Money(0, currency: "RON").isZero == true)
        #expect(Money(Decimal(string: "-0.0")!, currency: "RON").isZero == true)
    }

    @Test("isZero is driven by the decimal, not the formatted string")
    func isZeroUsesDecimal() {
        LocalePin.apply()
        // Rounds to "0 RON" for display but is not zero — the client must not infer zero
        // from the display string.
        let small = Money(Decimal(string: "0.4")!, currency: "RON")
        #expect(small.display == "0 RON")
        #expect(small.isZero == false)
    }
}
