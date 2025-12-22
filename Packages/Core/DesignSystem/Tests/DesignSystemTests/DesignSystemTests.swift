import Testing
import SwiftUI
@testable import DesignSystem

@Suite("DesignSystem Tests")
struct DesignSystemTests {

    // MARK: - Spacing Tests

    @Suite("Spacing Constants")
    struct SpacingTests {
        @Test("Spacing values follow 8pt grid")
        func spacingValues() {
            #expect(Spacing.xxs == 4)
            #expect(Spacing.xs == 8)
            #expect(Spacing.sm == 12)
            #expect(Spacing.md == 16)
            #expect(Spacing.lg == 24)
            #expect(Spacing.xl == 32)
            #expect(Spacing.xxl == 48)
        }

        @Test("Spacing values are positive")
        func spacingPositive() {
            #expect(Spacing.xxs > 0)
            #expect(Spacing.xs > 0)
            #expect(Spacing.sm > 0)
            #expect(Spacing.md > 0)
            #expect(Spacing.lg > 0)
            #expect(Spacing.xl > 0)
            #expect(Spacing.xxl > 0)
        }

        @Test("Spacing values increase in order")
        func spacingOrder() {
            #expect(Spacing.xxs < Spacing.xs)
            #expect(Spacing.xs < Spacing.sm)
            #expect(Spacing.sm < Spacing.md)
            #expect(Spacing.md < Spacing.lg)
            #expect(Spacing.lg < Spacing.xl)
            #expect(Spacing.xl < Spacing.xxl)
        }
    }

    // MARK: - Corner Radius Tests

    @Suite("Corner Radius Constants")
    struct CornerRadiusTests {
        @Test("Corner radius values are correct")
        func cornerRadiusValues() {
            #expect(CornerRadius.small == 8)
            #expect(CornerRadius.medium == 12)
            #expect(CornerRadius.large == 16)
            #expect(CornerRadius.xl == 24)
        }

        @Test("Corner radius values increase in order")
        func cornerRadiusOrder() {
            #expect(CornerRadius.small < CornerRadius.medium)
            #expect(CornerRadius.medium < CornerRadius.large)
            #expect(CornerRadius.large < CornerRadius.xl)
        }
    }

    // MARK: - Icon Size Tests

    @Suite("Icon Size Constants")
    struct IconSizeTests {
        @Test("Icon size values are correct")
        func iconSizeValues() {
            #expect(IconSize.sm == 16)
            #expect(IconSize.md == 24)
            #expect(IconSize.lg == 32)
            #expect(IconSize.xl == 48)
            #expect(IconSize.xxl == 64)
        }

        @Test("Icon size values increase in order")
        func iconSizeOrder() {
            #expect(IconSize.sm < IconSize.md)
            #expect(IconSize.md < IconSize.lg)
            #expect(IconSize.lg < IconSize.xl)
            #expect(IconSize.xl < IconSize.xxl)
        }
    }

    // MARK: - Color Tests

    @Suite("Color Hex Initializer")
    struct ColorHexTests {
        @Test("Color initializes from hex correctly")
        func colorFromHex() {
            let red = Color(hex: 0xFF0000)
            let green = Color(hex: 0x00FF00)
            let blue = Color(hex: 0x0000FF)

            // Colors should be created without crashing
            #expect(red != green)
            #expect(green != blue)
            #expect(red != blue)
        }

        @Test("Brand colors are defined")
        func brandColorsDefined() {
            // These should not crash when accessed
            let primaryLight = DiamerisColors.accentPrimaryLight
            let primaryDark = DiamerisColors.accentPrimaryDark
            let secondaryLight = DiamerisColors.accentSecondaryLight
            let secondaryDark = DiamerisColors.accentSecondaryDark

            // Light and dark variants should be different
            #expect(primaryLight != primaryDark)
            #expect(secondaryLight != secondaryDark)
        }

        @Test("Semantic colors are defined")
        func semanticColorsDefined() {
            // These should not crash when accessed
            _ = DiamerisColors.positive
            _ = DiamerisColors.negative
            _ = DiamerisColors.warning
            _ = DiamerisColors.neutral
        }
    }
}
