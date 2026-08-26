import Foundation
import Utilities
import Vapor

/// A monetary value on the wire: the exact decimal **and** the pre-formatted display strings.
///
/// Formatting happens here, server-side, using the very same `Utilities.AmountFormatter` that
/// the iOS app compiles. That is the whole point — iOS and web share one implementation, so
/// half-even rounding (`1182.5 → "1,182"`, `3547.5 → "3,548"`) is identical by construction
/// rather than by two codebases agreeing to be careful. The client formats nothing.
public struct Money: Content, Sendable, Hashable {
    /// Exact decimal, canonical form. The only field safe to compute with.
    public let amount: DecimalString
    /// Ready to render, currency code appended: `"1,182 RON"`.
    public let display: String
    /// For prefilled `<input>`s. `""` when the amount is <= 0, matching iOS.
    public let editing: String
    /// Whether the underlying decimal is exactly zero.
    ///
    /// Served because neither string is a safe zero test: `display` renders `-0.004` as
    /// **`"-0 RON"`** and `0.4` as `"0 RON"`, so `display == "0 RON"` is wrong in both directions.
    /// And `parseFloat(amount) === 0` would be client-side numeric logic, which R2 forbids.
    public let isZero: Bool

    public init(_ value: Decimal, currency: String) {
        self.amount = DecimalString(value)
        self.display = AmountFormatter.formatForDisplay(value, currency: currency)
        self.editing = AmountFormatter.formatForEditing(value)
        self.isZero = value == 0
    }
}

/// Turns `Decimal`s into `Money` with a fixed currency, so no call site has to remember it.
public struct MoneyFormatter: Sendable {
    public let currencyCode: String

    public init(currencyCode: String) {
        self.currencyCode = currencyCode
    }

    public init(currency: Currency) {
        self.currencyCode = currency.rawValue
    }

    public func callAsFunction(_ value: Decimal) -> Money {
        Money(value, currency: currencyCode)
    }

    public func callAsFunction(_ value: Decimal?) -> Money? {
        value.map { Money($0, currency: currencyCode) }
    }
}

/// The negated display for an expenses row: `"-4,270 RON"`, but **`"0 RON"` when the amount is
/// zero** — never `"-0 RON"`.
///
/// iOS gates the minus sign on `amount > 0` (`SummaryCard`'s `.negative` style,
/// `TransferPlanStep.swift:106`), so a zero total renders unsigned. Keyed off the **amount**, not
/// off `display == "0 RON"`: a string test would also strip the sign from a genuinely small
/// negative like `-0.004`, whose `"-0 RON"` we reproduce deliberately (R24).
public func negatedDisplay(_ money: Money) -> String {
    money.amount.value > 0 ? "-" + money.display : money.display
}

/// The `"+1,182 RON"` form for a transfer row, unsigned when the amount is zero — the mirror of
/// `negatedDisplay`, and guarded the same way so a zero row never reads `"+0 RON"`.
public func signedDisplay(_ money: Money) -> String {
    money.amount.value > 0 ? "+" + money.display : money.display
}

/// `Int(fraction * 100)` — **truncating**, which is what iOS does everywhere it renders a
/// percentage (`TransferPlan.progressChangeDisplay`, `SavingsAllocationEntry.percentageDisplay`,
/// `ExpenseBreakdownCard`). `0.0438 → 4`, not 4. Rounding here would silently desync the UI.
public func truncatedPercent(_ fraction: Double) -> Int {
    Int(fraction * 100)
}

public func percentDisplay(_ fraction: Double) -> String {
    "\(truncatedPercent(fraction))%"
}
