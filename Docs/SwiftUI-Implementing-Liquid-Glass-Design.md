# Implementing Liquid Glass Design in SwiftUI

## Overview

Liquid Glass is a dynamic material introduced in iOS that combines the optical properties of glass with a sense of fluidity. It blurs content behind it, reflects color and light from surrounding content, and reacts to touch and pointer interactions in real time. This guide covers how to implement and customize Liquid Glass effects in SwiftUI applications. You should always seek guides on Liquid Glass when asked for help adopting new Apple design.

Key features of Liquid Glass:
- Blurs content behind the material
- Reflects color and light from surrounding content
- Reacts to touch and pointer interactions
- Can morph between shapes during transitions
- Available for standard and custom components

## Basic Implementation

### Adding Liquid Glass to a View

The simplest way to add Liquid Glass to a view is using the `glassEffect()` modifier:

```swift
Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect()
```

By default, this applies the regular variant of Glass within a Capsule shape behind the view's content.

### Customizing the Shape

You can specify a different shape for the Liquid Glass effect:

```swift
Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect(in: .rect(cornerRadius: 16.0))
```

Common shape options:
- `.capsule` (default)
- `.rect(cornerRadius: CGFloat)`
- `.circle`

## Customizing Liquid Glass Effects

### Glass Variants and Properties

You can customize the Liquid Glass effect by configuring the `Glass` structure:

```swift
Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect(.regular.tint(.orange).interactive())
```

Key customization options:
- `.regular` - Standard glass effect
- `.tint(Color)` - Add a color tint to suggest prominence
- `.interactive(Bool)` - Make the glass react to touch and pointer interactions

### Making Interactive Glass

To make Liquid Glass react to touch and pointer interactions:

```swift
Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect(.regular.interactive(true))
```

Or more concisely:

```swift
Text("Hello, World!")
    .font(.title)
    .padding()
    .glassEffect(.regular.interactive())
```

## Working with Multiple Glass Effects

### Using GlassEffectContainer

When applying Liquid Glass effects to multiple views, use `GlassEffectContainer` for better rendering performance and to enable blending and morphing effects:

```swift
GlassEffectContainer(spacing: 40.0) {
    HStack(spacing: 40.0) {
        Image(systemName: "scribble.variable")
            .frame(width: 80.0, height: 80.0)
            .font(.system(size: 36))
            .glassEffect()

        Image(systemName: "eraser.fill")
            .frame(width: 80.0, height: 80.0)
            .font(.system(size: 36))
            .glassEffect()
    }
}
```

The `spacing` parameter controls how the Liquid Glass effects interact with each other:
- Smaller spacing: Views need to be closer to merge effects
- Larger spacing: Effects merge at greater distances

### Uniting Multiple Glass Effects

To combine multiple views into a single Liquid Glass effect, use the `glassEffectUnion` modifier:

```swift
@Namespace private var namespace

// Later in your view:
GlassEffectContainer(spacing: 20.0) {
    HStack(spacing: 20.0) {
        ForEach(symbolSet.indices, id: \.self) { item in
            Image(systemName: symbolSet[item])
                .frame(width: 80.0, height: 80.0)
                .font(.system(size: 36))
                .glassEffect()
                .glassEffectUnion(id: item < 2 ? "1" : "2", namespace: namespace)
        }
    }
}
```

This is useful when creating views dynamically or with views that live outside of an HStack or VStack.

## Morphing Effects and Transitions

### Creating Morphing Transitions

To create morphing effects during transitions between views with Liquid Glass:

1. Create a namespace using the `@Namespace` property wrapper
2. Associate each Liquid Glass effect with a unique identifier using `glassEffectID`
3. Use animations when changing the view hierarchy

```swift
@State private var isExpanded: Bool = false
@Namespace private var namespace

var body: some View {
    GlassEffectContainer(spacing: 40.0) {
        HStack(spacing: 40.0) {
            Image(systemName: "scribble.variable")
                .frame(width: 80.0, height: 80.0)
                .font(.system(size: 36))
                .glassEffect()
                .glassEffectID("pencil", in: namespace)

            if isExpanded {
                Image(systemName: "eraser.fill")
                    .frame(width: 80.0, height: 80.0)
                    .font(.system(size: 36))
                    .glassEffect()
                    .glassEffectID("eraser", in: namespace)
            }
        }
    }

    Button("Toggle") {
        withAnimation {
            isExpanded.toggle()
        }
    }
    .buttonStyle(.glass)
}
```

The morphing effect occurs when views with Liquid Glass appear or disappear due to view hierarchy changes.

## Button Styling with Liquid Glass

### Glass Button Style

SwiftUI provides built-in button styles for Liquid Glass:

```swift
Button("Click Me") {
    // Action
}
.buttonStyle(.glass)
```

### Glass Prominent Button Style

For a more prominent glass button:

```swift
Button("Important Action") {
    // Action
}
.buttonStyle(.glassProminent)
```

## Advanced Techniques

### Background Extension Effect

To stretch content behind a sidebar or inspector with the background extension effect:

```swift
NavigationSplitView {
    // Sidebar content
} detail: {
    // Detail content
        .background {
            // Background content that extends under the sidebar
        }
}
```

### Extending Horizontal Scrolling Under Sidebar

To extend horizontal scroll views under a sidebar or inspector:

```swift
ScrollView(.horizontal) {
    // Scrollable content
}
.scrollExtensionMode(.underSidebar)
```

## Best Practices

1. **Container Usage**: Always use `GlassEffectContainer` when applying Liquid Glass to multiple views for better performance and morphing effects.

2. **Effect Order**: Apply the `.glassEffect()` modifier after other modifiers that affect the appearance of the view.

3. **Spacing Consideration**: Carefully choose spacing values in containers to control how and when glass effects merge.

4. **Animation**: Use animations when changing view hierarchies to enable smooth morphing transitions.

5. **Interactivity**: Add `.interactive()` to glass effects that should respond to user interaction.

6. **Consistent Design**: Maintain consistent shapes and styles across your app for a cohesive look and feel.

## Example: Custom Badge with Liquid Glass

```swift
struct BadgeView: View {
    let symbol: String
    let color: Color

    var body: some View {
        ZStack {
            Image(systemName: "hexagon.fill")
                .foregroundColor(color)
                .font(.system(size: 50))

            Image(systemName: symbol)
                .foregroundColor(.white)
                .font(.system(size: 30))
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
    }
}

// Usage:
GlassEffectContainer(spacing: 20) {
    HStack(spacing: 20) {
        BadgeView(symbol: "star.fill", color: .blue)
        BadgeView(symbol: "heart.fill", color: .red)
        BadgeView(symbol: "leaf.fill", color: .green)
    }
}
```

## Troubleshooting & Common Pitfalls

### Menu with Custom Glass Label - Dismiss Animation Glitch

**Problem:** When using a `Menu` with a custom label that has `.glassEffect(.regular.interactive())` applied manually, the label content (e.g., text) gets momentarily cut off or glitches during the menu dismiss animation.

**Cause:** The manual `.interactive()` glass effect isn't coordinated with Menu's internal state management for presenting/dismissing its popover. When the menu closes, the interactive state change triggers a glass effect animation that conflicts with the dismiss animation, causing a brief layout glitch.

**Bad - Manual glass effect on Menu label:**
```swift
Menu {
    ForEach(options) { option in
        Button(option.name) { /* ... */ }
    }
} label: {
    HStack(spacing: 4) {
        Text("RON")
            .font(.headline)
        Image(systemName: "chevron.up.chevron.down")
            .font(.caption)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 8)) // ❌ Causes glitch
}
.buttonStyle(.plain)
```

**Good - Use built-in .buttonStyle(.glass):**
```swift
Menu {
    ForEach(options) { option in
        Button(option.name) { /* ... */ }
    }
} label: {
    HStack(spacing: 4) {
        Text("RON")
            .font(.headline)
        Image(systemName: "chevron.up.chevron.down")
            .font(.caption)
    }
}
.buttonStyle(.glass) // ✅ Properly handles Menu animation states
```

**Key Insight:** Always prefer `.buttonStyle(.glass)` or `.buttonStyle(.glassProminent)` for interactive elements like Buttons and Menus. The built-in styles properly coordinate with SwiftUI's internal animation states. Reserve manual `.glassEffect()` for static decorative elements or containers.

### Nested Glass Effects

**Problem:** Applying `.glassEffect()` to a view that's inside another view with `.glassEffect()` can cause unexpected visual artifacts.

**Solution:** Use `GlassEffectContainer` to wrap multiple glass effects, and avoid nesting interactive glass effects. If you need hierarchy, apply glass to the container level only.

## References

- [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)
- [Landmarks: Building an app with Liquid Glass](https://developer.apple.com/documentation/SwiftUI/Landmarks-Building-an-app-with-Liquid-Glass)
- [SwiftUI View.glassEffect(_:in:isEnabled:)](https://developer.apple.com/documentation/SwiftUI/View/glassEffect(_:in:isEnabled:))
- [SwiftUI GlassEffectContainer](https://developer.apple.com/documentation/SwiftUI/GlassEffectContainer)
- [SwiftUI GlassEffectTransition](https://developer.apple.com/documentation/SwiftUI/GlassEffectTransition)
- [SwiftUI GlassButtonStyle](https://developer.apple.com/documentation/SwiftUI/GlassButtonStyle)
