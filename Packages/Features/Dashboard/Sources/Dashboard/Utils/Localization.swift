import Foundation

extension String {
    var localized: String {
        String(localized: String.LocalizationValue(self), bundle: .module)
    }

    /// Use this for strings with variables: `String.localized("Hello \(name)")`
    static func localized(_ key: LocalizationValue) -> String {
        String(localized: key, bundle: .module)
    }
}
