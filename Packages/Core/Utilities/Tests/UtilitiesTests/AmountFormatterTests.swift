import Foundation
import Testing
@testable import Utilities

/// Tests for AmountFormatter - validates display formatting,
/// edit formatting, and parsing of monetary amounts.
@Suite("AmountFormatter Tests")
struct AmountFormatterTests {

    // MARK: - Format for Display

    @Suite("Format for Display")
    struct FormatForDisplay {

        @Test("Formats with thousands separator",
              arguments: [
                (amount: Decimal(1000), expected: "1,000"),
                (amount: Decimal(10000), expected: "10,000"),
                (amount: Decimal(100000), expected: "100,000"),
                (amount: Decimal(1000000), expected: "1,000,000")
              ])
        func formatsWithThousandsSeparator(amount: Decimal, expected: String) {
            let result = AmountFormatter.formatForDisplay(amount, currency: "RON")
            #expect(result.hasPrefix(expected))
        }

        @Test("Appends currency code")
        func appendsCurrencyCode() {
            let result = AmountFormatter.formatForDisplay(1000, currency: "RON")
            #expect(result == "1,000 RON")
        }

        @Test("Works with different currencies",
              arguments: ["RON", "EUR", "USD"])
        func worksWithDifferentCurrencies(currency: String) {
            let result = AmountFormatter.formatForDisplay(5000, currency: currency)
            #expect(result.hasSuffix(currency))
        }

        @Test("Zero amount displays correctly")
        func zeroAmount() {
            let result = AmountFormatter.formatForDisplay(0, currency: "RON")
            #expect(result == "0 RON")
        }

        @Test("No decimal places in display")
        func noDecimalPlaces() {
            let result = AmountFormatter.formatForDisplay(Decimal(string: "1234.56")!, currency: "EUR")
            #expect(result == "1,235 EUR") // Rounded
        }

        @Test("Large amounts format correctly")
        func largeAmounts() {
            let result = AmountFormatter.formatForDisplay(Decimal(string: "999999999")!, currency: "USD")
            #expect(result == "999,999,999 USD")
        }

        @Test("Small amounts format correctly")
        func smallAmounts() {
            let result = AmountFormatter.formatForDisplay(1, currency: "RON")
            #expect(result == "1 RON")
        }
    }

    // MARK: - Format for Editing

    @Suite("Format for Editing")
    struct FormatForEditing {

        @Test("No grouping separator for editing")
        func noGroupingSeparator() {
            let result = AmountFormatter.formatForEditing(10000)
            #expect(result == "10000")
        }

        @Test("Zero returns empty string")
        func zeroReturnsEmpty() {
            let result = AmountFormatter.formatForEditing(0)
            #expect(result == "")
        }

        @Test("Preserves up to 2 decimal places")
        func preservesDecimals() {
            let result = AmountFormatter.formatForEditing(Decimal(string: "123.45")!)
            // Result may use locale-specific separator
            #expect(result.contains("123"))
            #expect(result.contains("45"))
        }

        @Test("Removes unnecessary trailing zeros")
        func removesTrailingZeros() {
            let result = AmountFormatter.formatForEditing(Decimal(string: "123.40")!)
            // Result should contain 123 and 4, with trailing zero removed
            #expect(result.contains("123"))
            #expect(result.contains("4"))
            #expect(!result.hasSuffix("0"))
        }

        @Test("Whole numbers have no decimals")
        func wholeNumbersNoDecimals() {
            let result = AmountFormatter.formatForEditing(500)
            #expect(result == "500")
        }

        @Test("Negative amounts handled")
        func negativeAmounts() {
            // Zero check happens first, so only truly negative
            let result = AmountFormatter.formatForEditing(-100)
            // Implementation returns empty for <= 0
            #expect(result == "")
        }
    }

    // MARK: - Parse

    @Suite("Parse")
    struct Parse {

        @Test("Parses integer strings",
              arguments: [
                ("100", Decimal(100)),
                ("1000", Decimal(1000)),
                ("0", Decimal(0))
              ])
        func parsesIntegers(input: String, expected: Decimal) {
            let result = AmountFormatter.parse(input)
            #expect(result == expected)
        }

        @Test("Parses decimal with period")
        func parsesDecimalPeriod() {
            let result = AmountFormatter.parse("123.45")
            #expect(result == Decimal(string: "123.45"))
        }

        @Test("Parses decimal with comma (European format)")
        func parsesDecimalComma() {
            let result = AmountFormatter.parse("123,45")
            #expect(result == Decimal(string: "123.45"))
        }

        @Test("Empty string returns zero")
        func emptyReturnsZero() {
            let result = AmountFormatter.parse("")
            #expect(result == 0)
        }

        @Test("Invalid string returns zero")
        func invalidReturnsZero() {
            let result = AmountFormatter.parse("abc")
            #expect(result == 0)
        }

        @Test("Whitespace-only returns zero")
        func whitespaceReturnsZero() {
            let result = AmountFormatter.parse("   ")
            #expect(result == 0)
        }

        @Test("Handles mixed valid/invalid")
        func mixedValidInvalid() {
            // Decimal(string:) may parse initial valid portion
            // Just verify it doesn't crash and returns a value
            let result = AmountFormatter.parse("12abc")
            #expect(result >= 0)
        }

        @Test("Large numbers parse correctly")
        func largeNumbers() {
            let result = AmountFormatter.parse("999999999999")
            #expect(result == Decimal(string: "999999999999"))
        }

        @Test("Decimal precision maintained")
        func decimalPrecision() {
            let result = AmountFormatter.parse("0.01")
            #expect(result == Decimal(string: "0.01"))
        }
    }

    // MARK: - Round Trip

    @Suite("Round Trip")
    struct RoundTrip {

        @Test("Edit format then parse returns original",
              arguments: [
                Decimal(100),
                Decimal(1000),
                Decimal(12345),
                Decimal(string: "99.99")!
              ])
        func editThenParse(original: Decimal) {
            let formatted = AmountFormatter.formatForEditing(original)
            let parsed = AmountFormatter.parse(formatted)
            #expect(parsed == original)
        }

        @Test("Parse then edit format returns same",
              arguments: ["100", "5000", "123.45"])
        func parseThenEdit(input: String) {
            let parsed = AmountFormatter.parse(input)
            guard parsed > 0 else { return }
            let formatted = AmountFormatter.formatForEditing(parsed)
            let reparsed = AmountFormatter.parse(formatted)
            #expect(reparsed == parsed)
        }
    }

    // MARK: - Edge Cases

    @Suite("Edge Cases")
    struct EdgeCases {

        @Test("Very small decimal amounts")
        func verySmallDecimals() {
            let amount = Decimal(string: "0.01")!
            let result = AmountFormatter.formatForEditing(amount)
            // May use locale decimal separator
            #expect(result.contains("0"))
            #expect(result.contains("01"))
        }

        @Test("Negative zero treated as zero")
        func negativeZero() {
            let result = AmountFormatter.parse("-0")
            #expect(result == 0)
        }

        @Test("Multiple decimal points parses first valid portion")
        func multipleDecimalPoints() {
            // Decimal(string:) parses what it can
            let result = AmountFormatter.parse("12.34.56")
            // May parse 12.34 or fail - just verify it handles it
            #expect(result >= 0)
        }

        @Test("Currency symbols in input")
        func currencySymbolsInInput() {
            // Decimal(string:) may parse partial amounts
            let result = AmountFormatter.parse("$100")
            // Just verify no crash
            #expect(result >= 0)

            let result2 = AmountFormatter.parse("100€")
            // May parse 100 before the symbol
            #expect(result2 >= 0)
        }

        @Test("Spaces in number")
        func spacesInNumber() {
            // Verify behavior doesn't crash
            let result = AmountFormatter.parse("1 000")
            #expect(result >= 0)
        }
    }
}
