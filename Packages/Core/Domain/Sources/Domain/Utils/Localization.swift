import Foundation

extension String {
    /// Returns the localized version of this string from the Domain module's bundle
    var localized: String {
        String(localized: String.LocalizationValue(self), bundle: .module)
    }
}
