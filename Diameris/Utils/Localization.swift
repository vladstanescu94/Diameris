import Foundation

extension String {
    /// Returns a localized version of the string from the main app bundle.
    var localized: String {
        String(localized: String.LocalizationValue(self), bundle: .main)
    }

    /// Returns a localized string with interpolation from the main app bundle.
    static func localized(_ value: String) -> String {
        String(localized: String.LocalizationValue(value), bundle: .main)
    }
}
