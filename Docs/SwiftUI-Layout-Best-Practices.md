# SwiftUI Layout Best Practices

This document covers layout patterns and solutions for common SwiftUI challenges, particularly around text truncation and adaptive layouts.

---

## 1. Text Truncation Prevention

When SwiftUI's `Text` displays an ellipsis (truncation), it means the parent view isn't offering enough space. Text prioritizes truncating content rather than automatically pushing layout bounds or shrinking font size.

### Solutions

#### 1.1 `fixedSize` Modifier

Forces the view to take its ideal size, ignoring the proposed size from the parent.

```swift
// Allow vertical expansion, constrain horizontal
Text("Long text here")
    .fixedSize(horizontal: false, vertical: true)

// Never truncate (use sparingly - can break layouts)
Text("Important")
    .fixedSize()
```

**Use when:** Text must never truncate and layout can accommodate expansion.

#### 1.2 `minimumScaleFactor`

Allows font size reduction when space is constrained.

```swift
Text("Label")
    .minimumScaleFactor(0.7)  // Shrink up to 70% of original size
    .lineLimit(1)
```

**Use when:** Keeping text on one line is more important than consistent font size.

#### 1.3 `layoutPriority`

Controls which views get space first in a stack.

```swift
HStack {
    Text("Important label")
        .layoutPriority(1)  // Gets space first

    Spacer()

    Text("Secondary")
        .layoutPriority(0)  // Gets remaining space
}
```

**Use when:** You need to prioritize which elements get space in a stack.

---

## 2. ViewThatFits (iOS 16+)

`ViewThatFits` evaluates child views in order and selects the first one that fits within available space. This eliminates complex `GeometryReader` calculations.

### Basic Usage

```swift
ViewThatFits {
    // First choice - wide layout
    HStack {
        label
        Spacer()
        controls
    }

    // Fallback - compact layout
    VStack(alignment: .leading) {
        label
        controls
    }
}
```

### Axis Constraints

By default, ViewThatFits checks both axes. Constrain to specific axis when needed:

```swift
// Only check horizontal fit (useful in vertical ScrollView)
ViewThatFits(in: .horizontal) {
    WideView()
    CompactView()
}
```

### Text Handling

Text prefers single lines by default. ViewThatFits will prefer layouts that avoid text wrapping. To allow wrapping:

```swift
ViewThatFits(in: .vertical) {
    Text("Long text")
        .fixedSize(horizontal: false, vertical: true)
}
```

### Form Row Pattern

For form inputs with labels:

```swift
ViewThatFits(in: .horizontal) {
    // Wide: label and input side by side
    HStack {
        Text("Monthly Income")
        Spacer()
        TextField("0", text: $amount)
            .frame(width: 120)
    }

    // Compact: stacked vertically
    VStack(alignment: .leading, spacing: 8) {
        Text("Monthly Income")
        TextField("0", text: $amount)
    }
}
```

---

## 3. HStack Layout Algorithm

Understanding how HStack distributes space helps avoid layout issues:

1. **Flexibility calculation**: Stack orders children by flexibility (difference between widest and narrowest possible width)
2. **Least flexible first**: Views with fixed sizes get their space first
3. **Remaining space**: Distributed to flexible views (like `Spacer`, `Text`)

### Implications

- Views with `.fixedSize()` or `.frame(width:)` get priority
- `Spacer()` is infinitely flexible - gets leftover space
- `Text` without constraints is flexible and may truncate

### Best Practice for Form Rows

```swift
HStack {
    // Fixed elements first
    Image(systemName: "icon")
        .frame(width: 32)

    // Flexible label - can truncate if needed
    Text(label)
        .lineLimit(1)

    // Minimum gap
    Spacer(minLength: 8)

    // Fixed-width input section
    HStack {
        Text(currency)
            .fixedSize()  // Never truncate currency
        TextField("0", text: $amount)
            .frame(width: 80)
    }
    .fixedSize()  // Treat as single fixed-width unit
}
```

---

## 4. Common Patterns

### 4.1 Currency Input Field

```swift
struct CurrencyField: View {
    let currency: String
    @Binding var amount: String

    var body: some View {
        HStack(spacing: 4) {
            Text(currency)
                .foregroundStyle(.secondary)
            TextField("0", text: $amount)
                .multilineTextAlignment(.trailing)
        }
        .padding()
        .background(.regularMaterial)
    }
}
```

### 4.2 Adaptive List Row

```swift
struct AdaptiveRow: View {
    let title: String
    let value: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            // Wide
            HStack {
                Text(title)
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
            }

            // Narrow
            VStack(alignment: .leading) {
                Text(title)
                Text(value)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

### 4.3 Button Row (Actions)

```swift
ViewThatFits {
    // Side by side
    HStack(spacing: 16) {
        Button("Cancel") { }
        Button("Confirm") { }
    }

    // Stacked
    VStack(spacing: 12) {
        Button("Confirm") { }
        Button("Cancel") { }
    }
}
```

---

## 5. Debugging Layout Issues

### Check Proposed Size

```swift
Text("Debug")
    .background(GeometryReader { geo in
        Color.clear.onAppear {
            print("Proposed: \(geo.size)")
        }
    })
```

### Visualize Frames

```swift
.border(Color.red)  // See actual frame
.background(Color.blue.opacity(0.2))  // See background area
```

### Common Causes of Truncation

1. **Spacer without minLength**: Takes all available space
2. **Missing layoutPriority**: Important text doesn't get priority
3. **Nested stacks**: Proposal size reduces at each level
4. **Fixed widths too small**: Don't account for content variation

---

## References

- [ViewThatFits - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-create-an-adaptive-layout-with-viewthatfits)
- [Adaptive Layouts - Nil Coalescing](https://nilcoalescing.com/blog/AdaptiveLayoutsWithViewThatFits/)
- [fixedSize Modifier - Swift with Majid](https://swiftwithmajid.com/2020/04/29/the-magic-of-fixed-size-modifier-in-swiftui/)
- [Text Truncation Solutions - Fatbobman](https://fatbobman.com/en/snippet/ensuring-full-text-display-in-swiftui-techniques-and-solutions/)
- [SwiftUI Field Guide - HStack](https://www.swiftuifieldguide.com/layout/hstack/)
