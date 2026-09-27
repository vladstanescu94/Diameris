import SwiftUI
import UIKit

// MARK: - Brand Colors

/// Diameris brand color palette using programmatic adaptive colors.
/// Colors automatically adapt to light/dark mode without asset catalogs.
public enum DiamerisColors {
    // MARK: Primary Accent - Magenta/Fuchsia

    /// Light #A21CAF (Fuchsia-700), Dark #E879F9 (Fuchsia-400). Mostly used as text/icon tint, so
    /// light is the 700 shade: 6.3:1 on white vs 3.5:1 for Fuchsia-500 (WCAG AA needs 4.5:1).
    public static let accentPrimary = Color(
        light: Color(hex: 0xA21CAF),
        dark: Color(hex: 0xE879F9)
    )

    /// Fill for prominent buttons and other surfaces under white text: #A21CAF in both
    /// appearances (6.3:1 with white). The dark accent #E879F9 is only 2.5:1 under white.
    public static let accentPrimaryFill = Color(hex: 0xA21CAF)

    /// Primary accent fixed values (for cases where you need non-adaptive colors)
    public static let accentPrimaryLight = Color(hex: 0xA21CAF)
    public static let accentPrimaryDark = Color(hex: 0xE879F9)

    // MARK: Secondary Accent - Teal/Cyan

    /// Light #0E7490 (Cyan-700), Dark #22D3EE (Cyan-400). Cyan-700 is 5.4:1 on white; Cyan-500 was 2.4:1.
    public static let accentSecondary = Color(
        light: Color(hex: 0x0E7490),
        dark: Color(hex: 0x22D3EE)
    )

    /// Secondary accent fixed values (for cases where you need non-adaptive colors)
    public static let accentSecondaryLight = Color(hex: 0x0E7490)
    public static let accentSecondaryDark = Color(hex: 0x22D3EE)
}

// MARK: - Semantic Colors

public extension DiamerisColors {
    /// Positive values (income, gains) - uses secondary accent (teal)
    static let positive = accentSecondary

    /// Negative values (expenses, losses)
    static let negative = Color.red

    /// Warning states (approaching limits)
    static let warning = Color.orange

    /// Neutral/informational
    static let neutral = Color.secondary
}

// MARK: - Color Hex Initializer

public extension Color {
    /// Initialize a Color from a hex integer (e.g., 0xD946EF)
    init(hex: UInt, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }

    /// Initialize an adaptive Color with separate light and dark mode values.
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - View Extension for Brand Colors

public extension View {
    func accentPrimaryForeground() -> some View {
        foregroundStyle(DiamerisColors.accentPrimary)
    }

    func accentSecondaryForeground() -> some View {
        foregroundStyle(DiamerisColors.accentSecondary)
    }
}
