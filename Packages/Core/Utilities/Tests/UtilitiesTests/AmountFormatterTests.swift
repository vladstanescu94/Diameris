import Foundation
import Testing
@testable import Utilities

struct AmountFormatterTests {

    static let english = Locale(identifier: "en_US")
    static let romanian = Locale(identifier: "ro_RO")

    @Test(arguments: [
        ("8500", Decimal(8500)),
        ("1234.56", Decimal(string: "1234.56")!),
        ("1234,56", Decimal(string: "1234.56")!),
        ("1,234.56", Decimal(string: "1234.56")!),   // English with grouping
        ("1.234,56", Decimal(string: "1234.56")!),   // Romanian with grouping
        ("1.234.567", Decimal(1_234_567)),
        ("12 500 lei", Decimal(12_500)),
        (" 0,5 ", Decimal(string: "0.5")!),
        ("", Decimal(0)),
        ("abc", Decimal(0)),
        ("-250", Decimal(-250))
    ])
    func `Parses money typed in either convention`(text: String, expected: Decimal) {
        #expect(AmountFormatter.parse(text, locale: Self.english) == expected)
        #expect(AmountFormatter.parse(text, locale: Self.romanian) == expected)
    }

    @Test func `A lone three-digit group follows the locale's grouping separator`() {
        #expect(AmountFormatter.parse("1.234", locale: Self.romanian) == 1234)
        #expect(AmountFormatter.parse("1.234", locale: Self.english) == Decimal(string: "1.234"))
        #expect(AmountFormatter.parse("1,234", locale: Self.english) == 1234)
        #expect(AmountFormatter.parse("1,234", locale: Self.romanian) == Decimal(string: "1.234"))
    }

    @Test(arguments: [Self.english, Self.romanian], [Decimal(string: "1234.5")!, 14_303, Decimal(string: "0.01")!])
    func `Editing text round-trips through parse`(locale: Locale, amount: Decimal) {
        let text = AmountFormatter.formatForEditing(amount, locale: locale)
        #expect(AmountFormatter.parse(text, locale: locale) == amount, "\(text)")
    }

    @Test func `Editing uses the locale's decimal separator and leaves non-positive amounts blank`() {
        #expect(AmountFormatter.formatForEditing(Decimal(string: "1234.5")!, locale: Self.romanian) == "1234,5")
        #expect(AmountFormatter.formatForEditing(Decimal(string: "1234.567")!, locale: Self.english) == "1234.57")
        #expect(AmountFormatter.formatForEditing(0, locale: Self.english) == "")
        #expect(AmountFormatter.formatForEditing(-5, locale: Self.english) == "")
    }

    @Test(arguments: [
        (Decimal(14_303), Self.english, "14,303 RON"),
        (Decimal(14_303), Self.romanian, "14.303 RON"),
        (Decimal(1_500_000), Self.romanian, "1.500.000 RON"),
        (Decimal(string: "1234.56")!, Self.english, "1,235 RON"),
        (Decimal(string: "104.5")!, Self.romanian, "105 RON"),   // half up, not half even
        (Decimal(0), Self.english, "0 RON")
    ])
    func `Display groups thousands the locale's way and drops cents`(amount: Decimal, locale: Locale, expected: String) {
        #expect(AmountFormatter.formatForDisplay(amount, currency: "RON", locale: locale) == expected)
    }

    @Test(arguments: [Self.english, Self.romanian], ["1,500.50", "1.500,50", "1500", "0,5", "1.500"])
    func `Pasted amounts parse per locale`(locale: Locale, text: String) {
        let expected: Decimal = switch (text, locale.identifier) {
        case ("0,5", _): Decimal(string: "0.5")!
        case ("1500", _): 1500
        case ("1.500", "ro_RO"): 1500                    // "." groups thousands in Romanian
        case ("1.500", _): Decimal(string: "1.5")!
        default: Decimal(string: "1500.5")!
        }
        #expect(AmountFormatter.parse(text, locale: locale) == expected)
    }
}
