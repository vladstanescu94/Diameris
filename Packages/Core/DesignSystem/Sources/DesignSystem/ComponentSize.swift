import SwiftUI

/// Size constants for common UI components
public enum ComponentSize {
    // MARK: - Icon Containers

    /// 32pt - Standard icon container width for alignment in rows
    public static let iconContainer: CGFloat = 32

    // MARK: - Input Fields

    /// 80pt - Compact numeric input field width
    public static let compactInputWidth: CGFloat = 80

    /// 120pt - Medium input field width
    public static let mediumInputWidth: CGFloat = 120

    // MARK: - Progress Indicators

    /// 8pt - Small progress dot size
    public static let progressDot: CGFloat = 8

    /// 12pt - Medium progress dot size
    public static let progressDotMedium: CGFloat = 12

    // MARK: - Touch Targets

    /// 44pt - Minimum touch target size (Apple HIG)
    public static let minTouchTarget: CGFloat = 44

    /// 48pt - Comfortable touch target size
    public static let touchTarget: CGFloat = 48

    // MARK: - Buttons

    /// 50pt - Standard button height
    public static let buttonHeight: CGFloat = 50
}

// MARK: - Opacity Constants

public enum Opacity {
    /// 0.3 - Subtle/inactive state
    public static let subtle: Double = 0.3

    /// 0.5 - Half opacity
    public static let half: Double = 0.5

    /// 0.7 - Slightly dimmed
    public static let dimmed: Double = 0.7

    /// 0.85 - Nearly full
    public static let high: Double = 0.85
}
