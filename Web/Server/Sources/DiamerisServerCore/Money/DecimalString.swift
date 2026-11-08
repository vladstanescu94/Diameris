import Foundation

/// A `Decimal` that is **always** encoded to and decoded from a JSON *string*.
///
/// This is deliberate and load-bearing. Money in this app must survive a round trip exactly —
/// `1182.5` in, `1182.5` out — and a JSON *number* cannot guarantee that once a JavaScript
/// client touches it. Every monetary value in the store and on the wire goes through this type,
/// so there is no path where a float sneaks in.
///
/// Decoding rejects JSON numbers outright with an actionable message rather than silently
/// accepting the precision loss.
public struct DecimalString: Codable, Sendable, Hashable {
    public var value: Decimal

    public init(_ value: Decimal) {
        self.value = value
    }

    /// Canonical, locale-independent text form: `.` separator, no grouping, no currency.
    public var text: String {
        Self.canonicalText(value)
    }

    /// `Decimal.description` is already locale-independent and lossless for our range.
    /// Normalises `-0` to `0` so the wire form never carries a signed zero.
    public static func canonicalText(_ value: Decimal) -> String {
        value == 0 ? "0" : value.description
    }

    /// Parses a canonical decimal string. Locale-independent by construction — we never let the
    /// host locale decide whether `.` is a separator or a grouping mark.
    public static func parse(_ string: String) -> Decimal? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX"))
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Strings only. A number here is a client bug we want to surface loudly.
        guard let string = try? container.decode(String.self) else {
            throw DecodingError.typeMismatch(
                String.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: """
                        Monetary values must be sent as JSON strings, not numbers \
                        (e.g. "1182.5", not 1182.5). A JSON number cannot round-trip \
                        decimal money precisely.
                        """
                )
            )
        }

        guard let decimal = Self.parse(string) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "'\(string)' is not a valid decimal string."
                )
            )
        }
        self.value = decimal
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(text)
    }
}

extension DecimalString: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.value = Decimal(value)
    }
}

extension Decimal {
    /// Wraps this decimal for string-safe JSON encoding.
    var asDecimalString: DecimalString { DecimalString(self) }
}
