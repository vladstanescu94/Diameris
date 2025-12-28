import Foundation

extension String {
    /// Returns the localized version of this string from the Onboarding module's bundle
    var localized: String {
        String(localized: String.LocalizationValue(self), bundle: .module)
    }

    /// Returns a localized string with interpolation support.
    /// Use this for strings with variables: `String.localized("Hello \(name)")`
    static func localized(_ key: LocalizationValue) -> String {
        String(localized: key, bundle: .module)
    }
}
