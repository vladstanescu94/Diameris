import Foundation

extension String {
    /// Looked up at runtime in the app bundle, so Xcode can't extract these keys: add them to
    /// Localizable.xcstrings by hand (or use `String(localized:)` with a literal).
    var localized: String {
        String(localized: String.LocalizationValue(self), bundle: .main)
    }

    static func localized(_ value: String) -> String {
        String(localized: String.LocalizationValue(value), bundle: .main)
    }
}
