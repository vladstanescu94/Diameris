import Foundation

/// Pins the process locale so money formatting is byte-identical on every laptop (R7).
///
/// ### Why this is needed
/// `Utilities.AmountFormatter` builds a bare `NumberFormatter()`, which inherits
/// `Locale.current`. `formatForDisplay` forces the *grouping separator* to `","`, but the
/// grouping **size** and the negative form still come from the locale — so `100000` renders as
/// `"100,000"` on `en_US` and `"1,00,000"` on `en_IN`. `formatForEditing` doesn't even force the
/// separator, so `1182.5` becomes `"1182,5"` on a comma locale.
///
/// ### Why it is done like this
/// The clean fix would be a `locale:` parameter on `AmountFormatter`, but `Utilities` is iOS code
/// and only two changes to it are authorised, neither of them this. So instead of reimplementing
/// the formatter (which would defeat the entire point of sharing it), we change what
/// `Locale.current` *is* for this process.
///
/// Environment variables do **not** work — Foundation on macOS reads the locale from user
/// defaults, not `LANG`/`LC_ALL` (verified: `LC_ALL=en_US_POSIX` leaves `Locale.current` as
/// `en_US@rg=rozzzz`). Writing to the standard domain works but persists a plist. The
/// **volatile** argument domain works, has the highest precedence, and touches no disk.
///
/// Must be called before the first `Locale.current` access — i.e. first thing in `main`, and at
/// the top of any test that asserts formatted output.
public enum LocalePin {

    /// `en_US`, **not** `en_US_POSIX`.
    ///
    /// `en_US_POSIX` is the usual reflex for machine-stable formatting, and it is wrong here:
    /// it has `usesGroupingSeparator = false`, so `AmountFormatter`'s
    /// `formatter.groupingSeparator = ","` has nothing to apply and `9000` renders as
    /// `"9000 RON"` instead of `"9,000 RON"` — silently losing the thousands separator on every
    /// screen. Caught by the ground-truth suite.
    ///
    /// `en_US` gives everything we need and nothing we don't: grouping on at size 3, `.` as the
    /// decimal separator (so `editing` is `"1182.5"`), `-` prefix for negatives, and complete
    /// independence from the host's regional settings.
    public static let identifier = "en_US"

    private static let lock = NSLock()
    nonisolated(unsafe) private static var applied = false

    /// Idempotent. Safe to call from multiple test suites.
    public static func apply() {
        lock.lock()
        defer { lock.unlock() }
        guard !applied else { return }
        applied = true

        var domain = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
        domain["AppleLocale"] = identifier
        domain["AppleLanguages"] = [identifier]
        UserDefaults.standard.setVolatileDomain(domain, forName: UserDefaults.argumentDomain)
    }

    /// Whether the pin actually took effect. Surfaced so the server can log a warning rather
    /// than silently formatting against the host locale if a future Foundation stops honouring
    /// the volatile domain.
    public static var isEffective: Bool {
        Locale.current.identifier == identifier
    }
}
