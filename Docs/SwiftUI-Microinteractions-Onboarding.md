# SwiftUI Microinteractions & Onboarding Animations

## Overview

Microinteractions are subtle animations that make apps feel alive and premium. Research shows animated onboarding flows boost first-week retention to 67% vs 49% for static guides. Users who complete onboarding in under a minute show 50% higher retention rates.

## Animation Timing Guidelines

| Animation Type | Duration | Notes |
|----------------|----------|-------|
| Button tap feedback | 0.15-0.25s | Delays >0.3s feel laggy |
| Microinteractions | <300ms | Instant feedback feel |
| Screen transitions | 0.3-0.5s | Maintains engagement |
| Spring animations | response: 0.4-0.5, damping: 0.7-0.8 | Natural, bouncy feel |

## Physics-Based Animations

Prefer spring interpolations over standard easing curves for more natural feel:

```swift
// Snappy spring for buttons
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)

// Bouncy spring for transitions
.animation(.bouncy(duration: 0.4), value: currentStep)

// Smooth spring for morphing
.animation(.smooth(duration: 0.35), value: showContent)
```

## Key Microinteraction Patterns

### 1. Tap Pop (Button Feedback)
```swift
Button { } label: { }
    .scaleEffect(isPressed ? 0.92 : 1.0)
    .animation(.snappy(duration: 0.18), value: isPressed)
```

### 2. Icon Pulse (Hint at Interactivity)
```swift
Image(systemName: "arrow.right")
    .scaleEffect(isPulsing ? 1.08 : 1.0)
    .animation(.easeInOut(duration: 1.2).repeatForever(), value: isPulsing)
```

### 3. Glow Pulse (Glass UI Enhancement)
```swift
.shadow(color: .accent.opacity(glowing ? 0.6 : 0.2), radius: glowing ? 20 : 10)
.animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: glowing)
```

### 4. Slide-In with Spring
```swift
.offset(x: appeared ? 0 : -40)
.opacity(appeared ? 1 : 0)
.animation(.spring(response: 0.4, dampingFraction: 0.75), value: appeared)
```

### 5. Celebration Ripple
```swift
Circle()
    .scaleEffect(animating ? 2.8 : 0.1)
    .opacity(animating ? 0 : 0.8)
    .animation(.easeOut(duration: 0.55), value: animating)
```

## iOS 26 Liquid Glass Morphing

### GlassEffectContainer Setup
```swift
@Namespace private var namespace

GlassEffectContainer(spacing: 30) {
    // Views with glass effects will morph smoothly
    if showFirstView {
        firstView
            .glassEffect()
            .glassEffectID("main", in: namespace)
    } else {
        secondView
            .glassEffect()
            .glassEffectID("main", in: namespace)
    }
}
```

### Key Points
1. **Container Required**: Wrap morphing views in `GlassEffectContainer`
2. **Shared Namespace**: Use `@Namespace` for related animations
3. **Unique IDs**: Apply `glassEffectID` to every animated glass element
4. **Animate State Changes**: Use `withAnimation(.bouncy)` when toggling

### Morphing Between Screens
```swift
GlassEffectContainer(spacing: 40) {
    switch currentStep {
    case .name:
        NameContent()
            .glassEffectID("content", in: namespace)
    case .income:
        IncomeContent()
            .glassEffectID("content", in: namespace)
    }
}
```

## Haptic Feedback Integration

```swift
// Light tap for selections
UIImpactFeedbackGenerator(style: .light).impactOccurred()

// Medium for confirmations
UIImpactFeedbackGenerator(style: .medium).impactOccurred()

// Success notification
UINotificationFeedbackGenerator().notificationOccurred(.success)

// Soft for subtle interactions
UIImpactFeedbackGenerator(style: .soft).impactOccurred()
```

## Onboarding-Specific Patterns

### Progress Indicator Animation
```swift
// Animated progress dots/bar
.animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentStep)
```

### Staggered Content Appearance
```swift
ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
    ItemView(item: item)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8)
            .delay(Double(index) * 0.1),
            value: appeared
        )
}
```

### Celebration on Completion
- Confetti particle effect
- Scale bounce of success icon
- Ripple effect from center
- Haptic success notification

## Accessibility Considerations

Always respect reduced motion preferences:

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

.animation(reduceMotion ? .none : .spring(...), value: state)
```

## Sources

- [Micro-Interactions in SwiftUI — Subtle Animations That Make Apps Feel Premium](https://dev.to/sebastienlato/micro-interactions-in-swiftui-subtle-animations-that-make-apps-feel-premium-2ldn)
- [Transforming Glass Views with glassEffectID in SwiftUI](https://serialcoder.dev/text-tutorials/swiftui/transforming-glass-views-with-the-glasseffectid-modifier-in-swiftui/)
- [iOS 2025 UX Trends: Micro-interactions & Fluid Animations](https://medium.com/@bhumibhuva18/hot-ios-2025-ux-trends-micro-interactions-fluid-animations-and-design-principles-developers-b52673769cd6)
- [Designing Onboarding Microinteractions Guide](https://www.uxpin.com/studio/blog/designing-onboarding-microinteractions-guide/)
- [Creating Engaging Onboarding Screens in SwiftUI](https://medium.com/@sagar.ajudiya/creating-engaging-onboarding-screens-in-swiftui-803e9f611ea7)
- [Apple Developer: Applying Liquid Glass to Custom Views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views)
