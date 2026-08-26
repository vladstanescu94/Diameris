#if canImport(UIKit)

import UIKit

/// Centralized haptic feedback manager for consistent tactile feedback.
public enum HapticManager {
    // MARK: - Impact Feedback

    /// Light tap - for selections, toggles
    public static func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium tap - for confirmations, button presses
    public static func mediumTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Soft tap - for subtle interactions, focus changes
    public static func softTap() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }

    /// Rigid tap - for solid, definitive actions
    public static func rigidTap() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }

    // MARK: - Notification Feedback

    /// Success - for completed actions, achievements
    public static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Warning - for caution states
    public static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Error - for failed actions
    public static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    // MARK: - Selection Feedback

    /// Selection changed - for pickers, segments
    public static func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

#endif
