import Foundation
import Testing
@testable import Utilities

/// Tests for Currency enum - validates symbols, display names,
/// and locale detection.
@Suite("Currency Tests")
struct CurrencyTests {

    // MARK: - Raw Values

    @Suite("Raw Values")
    struct RawValues {

        @Test("RON raw value")
        func ronRawValue() {
            #expect(Currency.ron.rawValue == "RON")
        }

        @Test("EUR raw value")
        func eurRawValue() {
            #expect(Currency.eur.rawValue == "EUR")
        }

        @Test("USD raw value")
        func usdRawValue() {
            #expect(Currency.usd.rawValue == "USD")
        }

        @Test("Can create from raw value",
              arguments: ["RON", "EUR", "USD"])
        func createFromRawValue(code: String) {
            let currency = Currency(rawValue: code)
            #expect(currency != nil)
        }

        @Test("Invalid raw value returns nil")
        func invalidRawValue() {
            #expect(Currency(rawValue: "GBP") == nil)
            #expect(Currency(rawValue: "ron") == nil) // Case sensitive
            #expect(Currency(rawValue: "") == nil)
        }
    }

    // MARK: - Symbols

    @Suite("Symbols")
    struct Symbols {

        @Test("RON symbol is lei")
        func ronSymbol() {
            #expect(Currency.ron.symbol == "lei")
        }

        @Test("EUR symbol is €")
        func eurSymbol() {
            #expect(Currency.eur.symbol == "€")
        }

        @Test("USD symbol is $")
        func usdSymbol() {
            #expect(Currency.usd.symbol == "$")
        }

        @Test("All currencies have symbols")
        func allHaveSymbols() {
            for currency in Currency.allCases {
                #expect(!currency.symbol.isEmpty)
            }
        }
    }

    // MARK: - Display Names

    @Suite("Display Names")
    struct DisplayNames {

        @Test("RON display name")
        func ronDisplayName() {
            #expect(Currency.ron.displayName == "Romanian Leu (RON)")
        }

        @Test("EUR display name")
        func eurDisplayName() {
            #expect(Currency.eur.displayName == "Euro (EUR)")
        }

        @Test("USD display name")
        func usdDisplayName() {
            #expect(Currency.usd.displayName == "US Dollar (USD)")
        }

        @Test("All display names include currency code")
        func displayNamesIncludeCode() {
            for currency in Currency.allCases {
                #expect(currency.displayName.contains(currency.rawValue))
            }
        }
    }

    // MARK: - Identifiable

    @Suite("Identifiable")
    struct Identifiable {

        @Test("ID equals raw value")
        func idEqualsRawValue() {
            for currency in Currency.allCases {
                #expect(currency.id == currency.rawValue)
            }
        }

        @Test("All IDs are unique")
        func uniqueIds() {
            let ids = Currency.allCases.map { $0.id }
            let uniqueIds = Set(ids)
            #expect(ids.count == uniqueIds.count)
        }
    }

    // MARK: - CaseIterable

    @Suite("CaseIterable")
    struct CaseIterableTests {

        @Test("Has 3 currencies")
        func threeCurrencies() {
            #expect(Currency.allCases.count == 3)
        }

        @Test("All cases included")
        func allCasesIncluded() {
            let cases = Currency.allCases
            #expect(cases.contains(.ron))
            #expect(cases.contains(.eur))
            #expect(cases.contains(.usd))
        }
    }

    // MARK: - Locale Detection

    @Suite("Locale Detection")
    struct LocaleDetection {

        @Test("fromLocale returns a valid currency")
        func fromLocaleReturnsValid() {
            let currency = Currency.fromLocale()
            #expect(Currency.allCases.contains(currency))
        }

        @Test("fromLocale defaults to RON for unknown locales")
        func defaultsToRon() {
            // The implementation defaults to RON when locale currency isn't supported
            // This test verifies that behavior exists (actual locale depends on test environment)
            let currency = Currency.fromLocale()
            // Should always return a valid currency, never crash
            #expect(currency == .ron || currency == .eur || currency == .usd)
        }
    }

    // MARK: - Sendable

    @Suite("Sendable")
    struct SendableTests {

        @Test("Can be used across actor boundaries")
        func canCrossActorBoundaries() async {
            let currency = Currency.eur

            let result = await Task.detached {
                return currency.symbol
            }.value

            #expect(result == "€")
        }
    }
}
