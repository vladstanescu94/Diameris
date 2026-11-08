import Foundation

/// Rounding rules that keep plan amounts transferable.
///
/// Every amount the plan produces is something the user types into a banking app, so it must be
/// whole cents: `Decimal / 12` or a proportional split otherwise leaves 38-digit repeating tails
/// (`99.999…96`) that never add back up to the income.
enum Money {
    /// Fraction digits of a transferable amount (RON bani, EUR cents, USD cents).
    static let minorUnitScale = 2

    /// Fraction digits kept from a `Double` rate before it touches money. 4 digits = 0.01%.
    static let rateScale = 4
}

extension Decimal {
    var roundedToCents: Decimal {
        rounded(scale: Money.minorUnitScale)
    }

    /// A `Double` rate (percentage, multiplier) as a `Decimal`, without binary noise.
    ///
    /// `Decimal(0.07)` is `0.07000000000000001024`, and `0.1 * 3` is `0.30000000000000004`; either
    /// multiplied into a salary leaks sub-cent garbage into every downstream amount.
    init(rate: Double) {
        self = Decimal(rate).rounded(scale: Money.rateScale)
    }

    func rounded(scale: Int, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, mode)
        return result
    }
}

extension Double {
    /// Whole percent in the user's locale ("20%", "20 %"), rounded to nearest — the same rule as
    /// SwiftUI's `.percent` format, so a card's ring and its text never disagree.
    var wholePercentText: String {
        formatted(.percent.precision(.fractionLength(0)))
    }
}
