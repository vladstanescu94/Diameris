import Foundation
import Testing
@testable import Utilities

struct CurrencyTests {

    @Test(arguments: zip(
        ["ro_RO", "de_DE", "en_US", "en_GB"],
        [Currency.ron, .eur, .usd, .ron]
    ))
    func `Default currency comes from the locale, falling back to RON`(identifier: String, expected: Currency) {
        #expect(Currency.fromLocale(Locale(identifier: identifier)) == expected)
    }

    @Test func `Display name is in the user's language`() {
        #expect(Currency.ron.displayName(locale: Locale(identifier: "en_US")) == "Romanian Leu (RON)")
        #expect(Currency.eur.displayName(locale: Locale(identifier: "en_US")) == "Euro (EUR)")
        #expect(Currency.ron.displayName(locale: Locale(identifier: "ro_RO")) == "leu românesc (RON)")
    }

    /// Stored as `UserProfile.currencyCode`; renaming a case orphans the user's choice.
    @Test func `Raw values are ISO codes`() {
        #expect(Currency.allCases.map(\.rawValue) == ["RON", "EUR", "USD"])
    }
}
