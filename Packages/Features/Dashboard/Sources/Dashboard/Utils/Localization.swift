import Foundation

extension String {
    /// Localizes a string using the module's bundle.
    var localized: String {
        String(localized: String.LocalizationValue(self), bundle: .module)
    }
}
