import SwiftUI

/// Animation duration constants for consistent motion design
public enum AnimationDuration {
    /// 0.15s - Quick tap feedback
    public static let quick: Double = 0.15

    /// 0.2s - Fast micro-interaction
    public static let fast: Double = 0.2

    /// 0.3s - Standard interaction
    public static let standard: Double = 0.3

    /// 0.4s - Medium transition
    public static let medium: Double = 0.4

    /// 0.5s - Slow, deliberate animation
    public static let slow: Double = 0.5

    /// 0.6s - Extended animation for emphasis
    public static let extended: Double = 0.6

    /// 1.0s - Long animation for celebrations
    public static let celebration: Double = 1.0
}

/// Spring animation presets for consistent physics
public enum SpringPreset {
    /// Quick, snappy spring for button feedback
    public static let snappy = Animation.spring(response: 0.2, dampingFraction: 0.6)

    /// Responsive spring for UI transitions
    public static let responsive = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Standard spring for content appearance
    public static let standard = Animation.spring(response: 0.4, dampingFraction: 0.75)

    /// Smooth spring for screen transitions
    public static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.8)

    /// Bouncy spring for celebratory animations
    public static let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)

    /// Gentle spring for subtle movements
    public static let gentle = Animation.spring(response: 0.6, dampingFraction: 0.85)
}

/// Stagger delay constants for sequential animations
public enum StaggerDelay {
    /// 0.05s - Very fast stagger
    public static let fast: Double = 0.05

    /// 0.1s - Standard stagger between items
    public static let standard: Double = 0.1

    /// 0.15s - Comfortable stagger
    public static let comfortable: Double = 0.15

    /// 0.3s - Initial delay before stagger starts
    public static let initial: Double = 0.3
}

/// Scale values for press states and animations
public enum ScaleEffect {
    /// 0.92 - Deep press effect
    public static let pressedDeep: CGFloat = 0.92

    /// 0.95 - Standard press effect
    public static let pressed: CGFloat = 0.95

    /// 0.97 - Subtle press effect
    public static let pressedSubtle: CGFloat = 0.97

    /// 1.03 - Slight hover/emphasis
    public static let emphasized: CGFloat = 1.03

    /// 1.08 - Pulse effect peak
    public static let pulse: CGFloat = 1.08

    /// 1.1 - Prominent scale up
    public static let prominent: CGFloat = 1.1
}

/// Offset values for slide animations
public enum SlideOffset {
    /// 10pt - Subtle slide
    public static let subtle: CGFloat = 10

    /// 15pt - Small slide
    public static let small: CGFloat = 15

    /// 20pt - Standard slide
    public static let standard: CGFloat = 20

    /// 30pt - Large slide
    public static let large: CGFloat = 30

    /// 40pt - Extra large slide
    public static let xl: CGFloat = 40
}
