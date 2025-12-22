# Diameris - Design Guidelines

## Overview

This document establishes Diameris's visual identity and design standards. Diameris follows Apple's Human Interface Guidelines while maintaining its own distinctive personality as a modern, trustworthy finance app.

**Target Platforms:** iOS 26+, iPadOS 26+, macOS Tahoe (future)
**Design Language:** Apple Liquid Glass (2025)

---

## 1. Design Philosophy

### Apple HIG Core Principles

| Principle | Application in Diameris |
|-----------|------------------------|
| **Clarity** | Clean layouts, legible typography, obvious touch targets |
| **Deference** | UI supports content (your financial data), not distracts from it |
| **Depth** | Visual hierarchy through Liquid Glass layers and subtle shadows |
| **Consistency** | Uniform patterns across all screens and interactions |

### Diameris Identity

**Professional + Cool + Modern**

- **Trustworthy:** Users entrust their financial data to this app
- **Modern:** Fresh, contemporary feel - not a boring banking app
- **Clean:** Purposeful use of color and space
- **Delightful:** Subtle touches that reward attention

---

## 2. Liquid Glass Integration

Liquid Glass is Apple's 2025 design language. See `SwiftUI-Implementing-Liquid-Glass-Design.md` for implementation details.

### When to Use

| Component | Approach |
|-----------|----------|
| Cards & containers | `.glassEffect(in: .rect(cornerRadius: 16))` |
| Primary buttons | `.buttonStyle(.glassProminent)` |
| Secondary buttons | `.buttonStyle(.glass)` |
| Grouped controls | `GlassEffectContainer` |
| Interactive elements | `.glassEffect(.regular.interactive())` |

### Best Practices

- Use `GlassEffectContainer` when multiple glass elements are near each other
- Apply `.glassEffectID()` with `@Namespace` for morphing transitions
- Tint glass sparingly with accent colors for emphasis
- Let glass blur create natural depth hierarchy

---

## 3. Typography

### Font System

Use San Francisco (SF Pro) exclusively via SwiftUI's semantic text styles.

```swift
// DO: Use semantic styles
Text("Monthly Budget")
    .font(.title)

Text("$1,234.56")
    .font(.largeTitle)
    .fontWeight(.bold)

Text("Last updated today")
    .font(.caption)
    .foregroundStyle(.secondary)

// DON'T: Hardcode font sizes
Text("Budget").font(.system(size: 24)) // Avoid
```

### Text Style Hierarchy

| Style | Usage |
|-------|-------|
| `.largeTitle` | Main amounts, hero numbers |
| `.title` | Screen titles, section headers |
| `.title2`, `.title3` | Subsection headers |
| `.headline` | Card titles, emphasis |
| `.body` | Primary content |
| `.callout` | Supporting info |
| `.subheadline` | Secondary labels |
| `.footnote` | Tertiary info |
| `.caption`, `.caption2` | Timestamps, metadata |

### Requirements

- **Minimum size:** 11pt (accessibility requirement)
- **Default body:** 17pt
- **Dynamic Type:** Full support required - test with all size categories
- **Contrast:** Ensure legibility over Liquid Glass (test both appearances)

---

## 4. SF Symbols

### Version & Resources

- **SF Symbols 7** (6,900+ symbols)
- Download SF Symbols app from [developer.apple.com/sf-symbols](https://developer.apple.com/sf-symbols/)

### Rendering Modes

| Mode | When to Use |
|------|-------------|
| **Monochrome** | Default, single-color contexts |
| **Hierarchical** | Add depth with opacity layers |
| **Palette** | Custom multi-color schemes |
| **Multicolor** | When symbol has inherent colors (flags, etc.) |

### Context Guidelines

| Context | Variant | Example |
|---------|---------|---------|
| Tab bar | Fill | `chart.pie.fill`, `target` |
| Navigation bar | Outline | `plus`, `gear` |
| List rows | Outline or hierarchical | `creditcard`, `banknote` |
| Action buttons | Fill for primary | `plus.circle.fill` |

### Animations

SF Symbols 7 supports Draw On/Off animations for expressive UI:

```swift
Image(systemName: "checkmark.circle")
    .symbolEffect(.bounce, value: isComplete)
```

### Custom Symbols

Only create custom symbols when SF Symbols lacks an appropriate option. Export similar symbol as template and modify in vector editor.

---

## 5. Color System

### Brand Colors

**Primary Accent - Magenta/Fuchsia**
```swift
// Light mode
Color(hex: "#D946EF") // Fuchsia-500

// Dark mode (slightly brighter)
Color(hex: "#E879F9") // Fuchsia-400
```

**Secondary Accent - Teal/Cyan**
```swift
// Light mode
Color(hex: "#06B6D4") // Cyan-500

// Dark mode (slightly brighter)
Color(hex: "#22D3EE") // Cyan-400
```

### Semantic Colors

| Purpose | Color | Notes |
|---------|-------|-------|
| Income / Positive | Teal accent or `.green` | Use teal for brand consistency |
| Expenses / Negative | `.red` | Never use magenta for negative |
| Neutral | System grays | Labels, dividers, backgrounds |
| Warning | `.orange` | Alerts, approaching limits |

### Light & Dark Mode

Define colors in Asset Catalog with both appearances:

```
AccentPrimary
├── Any Appearance: #D946EF
└── Dark: #E879F9

AccentSecondary
├── Any Appearance: #06B6D4
└── Dark: #22D3EE
```

Access in code:
```swift
Color("AccentPrimary")
```

### Usage Guidelines

- **Accent usage:** Limit to ~10-15% of UI surface
- **Backgrounds:** Use muted/desaturated versions of brand colors
- **Contrast:** Test WCAG AA compliance in both modes
- **High Contrast:** Support increased contrast accessibility setting

---

## 6. Responsive Design

### Platform Adaptations

| Platform | Layout | Navigation |
|----------|--------|------------|
| iPhone | Compact horizontal | `NavigationStack` |
| iPad | Regular horizontal | `NavigationSplitView` with sidebar |
| Mac (future) | Regular | `NavigationSplitView` |

### Adaptive Layout Tools

```swift
// Size classes
@Environment(\.horizontalSizeClass) var sizeClass

// Automatic adaptation
NavigationSplitView {
    Sidebar()
} detail: {
    DetailView()
}
// Automatically becomes stack on iPhone

// Choose best-fitting layout
ViewThatFits {
    HStack { content }
    VStack { content }
}

// Responsive grids
LazyVGrid(columns: [
    GridItem(.adaptive(minimum: 160))
]) {
    ForEach(items) { item in
        CardView(item: item)
    }
}
```

### Guidelines

- **No hardcoded dimensions** - use relative sizing
- **Test on multiple devices** - iPhone SE through iPad Pro
- **Respect safe areas** - use `.safeAreaInset()` appropriately
- **Adapt, don't just scale** - iPad should feel native, not stretched iPhone

---

## 7. Touch Targets & Accessibility

### Touch Targets

- **Minimum:** 44×44pt for all interactive elements
- **Comfortable:** 48×48pt or larger preferred

```swift
Button(action: {}) {
    Image(systemName: "plus")
}
.frame(minWidth: 44, minHeight: 44)
```

### Accessibility Requirements

| Feature | Implementation |
|---------|----------------|
| VoiceOver | `.accessibilityLabel()` on all interactive elements |
| Dynamic Type | Use semantic text styles, test all sizes |
| Reduce Motion | Check `AccessibilityReduceMotion` environment value |
| High Contrast | Support `accessibilityContrast` |

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// Respect user preference
withAnimation(reduceMotion ? nil : .spring()) {
    // state change
}
```

---

## 8. Custom Components

### Design Principles

- **Apple-like but with taste** - follow conventions, add subtle personality
- **Consistent corner radii** - 12-16pt for cards, 8pt for smaller elements
- **8pt spacing grid** - all spacing should be multiples of 8

### Spacing System

```swift
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
```

### Corner Radii

```swift
enum CornerRadius {
    static let small: CGFloat = 8    // Chips, tags
    static let medium: CGFloat = 12  // Buttons, small cards
    static let large: CGFloat = 16   // Cards, sheets
    static let xl: CGFloat = 24      // Large containers
}
```

---

## 9. Microinteractions & Delight

### Philosophy

Small, thoughtful animations add personality even if users don't consciously notice them. These create a premium, polished feel.

### Implementation Examples

**Button Feedback**
```swift
Button(action: action) {
    Label("Add Expense", systemImage: "plus")
}
.buttonStyle(.glass)
.sensoryFeedback(.impact(weight: .light), trigger: tapCount)
```

**Card Press Effect**
```swift
struct PressableCard<Content: View>: View {
    @State private var isPressed = false
    let content: Content

    var body: some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}
```

**Animated Numbers**
```swift
Text(amount, format: .currency(code: "RON"))
    .contentTransition(.numericText())
    .animation(.spring(), value: amount)
```

**Staggered List Animation**
```swift
ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
    ItemRow(item: item)
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .opacity
        ))
        .animation(.spring().delay(Double(index) * 0.05), value: items)
}
```

### Microinteraction Catalog

| Interaction | Effect |
|-------------|--------|
| Button tap | Scale 0.98 + haptic `.impact(weight: .light)` |
| Card press | Slight scale + lift shadow |
| Progress update | Smooth spring animation on ring/bar |
| Number change | `.contentTransition(.numericText())` |
| List load | Staggered fade-in |
| Success milestone | Haptic `.success` + optional confetti |
| Swipe reveal | Bouncy spring + haptic |
| Tab switch | SF Symbol morphing |

### Technical Guidelines

- Use `.spring()` for natural feel (default response: 0.5)
- Prefer `withAnimation {}` for state-driven transitions
- Always respect "Reduce Motion" setting
- Use `.sensoryFeedback()` for appropriate haptics
- Keep animations under 300ms for responsiveness

---

## 10. App Personality Summary

### Diameris Design DNA

| Attribute | Expression |
|-----------|------------|
| **Professional** | Clean layouts, clear hierarchy, trustworthy feel |
| **Cool** | Magenta/teal accent colors, modern Liquid Glass |
| **Modern** | 2025 design language, fluid animations |
| **Personal** | Celebrates wins, thoughtful microinteractions |

### Visual Principles

1. **Generous whitespace** - Let content breathe
2. **Purposeful color** - Every accent earns its place
3. **Celebrate wins** - Milestone animations reward progress
4. **Premium without flash** - Subtle polish over showy effects
5. **Every element earns its place** - No visual clutter

---

## References

- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Typography Guidelines](https://developer.apple.com/design/human-interface-guidelines/typography)
- [Designing for iOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-ios)
- [SwiftUI-Implementing-Liquid-Glass-Design.md](./SwiftUI-Implementing-Liquid-Glass-Design.md) (local)
