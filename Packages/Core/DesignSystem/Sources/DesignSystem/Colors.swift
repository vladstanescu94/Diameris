import SwiftUI

// MARK: - Brand Colors

/// Diameris brand color palette
public enum DiamerisColors {
    // MARK: Primary Accent - Magenta/Fuchsia

    /// Primary brand accent color (Magenta/Fuchsia)
    /// Light: #D946EF (Fuchsia-500), Dark: #E879F9 (Fuchsia-400)
    public static let accentPrimary = Color("AccentPrimary", bundle: .main)

    /// Primary accent as hex for programmatic use
    public static let accentPrimaryLight = Color(hex: 0xD946EF)
    public static let accentPrimaryDark = Color(hex: 0xE879F9)

    // MARK: Secondary Accent - Teal/Cyan

    /// Secondary brand accent color (Teal/Cyan)
    /// Light: #06B6D4 (Cyan-500), Dark: #22D3EE (Cyan-400)
    public static let accentSecondary = Color("AccentSecondary", bundle: .main)

    /// Secondary accent as hex for programmatic use
    public static let accentSecondaryLight = Color(hex: 0x06B6D4)
    public static let accentSecondaryDark = Color(hex: 0x22D3EE)
}

// MARK: - Semantic Colors

public extension DiamerisColors {
    /// Positive values (income, gains) - uses secondary accent (teal)
    static let positive = accentSecondaryLight

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
}

// MARK: - View Extension for Brand Colors

public extension View {
    /// Apply the primary brand accent as foreground color
    func accentPrimaryForeground() -> some View {
        foregroundStyle(DiamerisColors.accentPrimary)
    }

    /// Apply the secondary brand accent as foreground color
    func accentSecondaryForeground() -> some View {
        foregroundStyle(DiamerisColors.accentSecondary)
    }
}
