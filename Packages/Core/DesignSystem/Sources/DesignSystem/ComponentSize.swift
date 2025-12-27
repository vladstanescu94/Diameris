import SwiftUI

/// Size constants for common UI components
public enum ComponentSize {
    // MARK: - Icon Containers

    /// 32pt - Standard icon container width for alignment in rows
    public static let iconContainer: CGFloat = 32

    // MARK: - Input Fields

    /// 60pt - Small amount input width (for inline currency inputs)
    public static let amountInputWidth: CGFloat = 60

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

    /// 36pt - Small button height (secondary actions)
    public static let buttonHeightSmall: CGFloat = 36

    // MARK: - Celebration Effects

    /// 200pt - Celebration ring container size
    public static let celebrationRingSize: CGFloat = 200

    /// 8pt - Confetti particle width
    public static let confettiWidth: CGFloat = 8

    /// 12pt - Confetti particle height
    public static let confettiHeight: CGFloat = 12

    // MARK: - Progress Bar

    /// 4pt - Progress track height
    public static let progressTrackHeight: CGFloat = 4

    /// 18pt - Progress indicator outer ring size
    public static let progressRingSize: CGFloat = 18

    /// 280pt - Maximum progress bar width
    public static let progressBarMaxWidth: CGFloat = 280

    /// 24pt - Progress indicator container height
    public static let progressIndicatorHeight: CGFloat = 24

    /// 0.6 - Progress bar width as fraction of container
    public static let progressBarWidthFraction: CGFloat = 0.6

    /// 0.05 - Minimum progress fill scale (ensures visibility at 0%)
    public static let progressMinFillScale: CGFloat = 0.05
}

// MARK: - Opacity Constants

public enum Opacity {
    /// 0.3 - Subtle/inactive state
    public static let subtle: Double = 0.3

    /// 0.5 - Half opacity
    public static let half: Double = 0.5

    /// 0.6 - Medium opacity (pressed states)
    public static let medium: Double = 0.6

    /// 0.7 - Slightly dimmed
    public static let dimmed: Double = 0.7

    /// 0.85 - Nearly full
    public static let high: Double = 0.85
}
