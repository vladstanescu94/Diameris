import Foundation

extension String {
    /// Returns a localized string using the Expenses module bundle.
    var localized: String {
        String(localized: String.LocalizationValue(self), bundle: .module)
    }
}
