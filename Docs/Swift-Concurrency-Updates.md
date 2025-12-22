# Concurrent Programming Updates in Swift 6.2

## Overview

Swift 6.2 fundamentally shifts its approach to concurrency by staying single threaded by default until you choose to introduce concurrency. This philosophy makes writing safe concurrent code more accessible to developers.

## Key Changes

### Data-Race Safety Improvements

The update addresses two major pain points:

**1. Async functions on mutable types:** Rather than eagerly offloading async work, functions now continue to run on the actor they were called from, eliminating unnecessary data race concerns when the most natural code is written.

**2. Isolated conformances:** Developers can now implement protocol conformances on main actor types using `@MainActor Exportable` syntax. A conformance that needs main actor state is called an *isolated* conformance, which the compiler ensures is only called on the main actor.

## Global State Management

A new opt-in mode infers main actor isolation by default, automatically protecting static variables and reducing boilerplate annotations. This is recommended for apps, scripts, and other executable targets.

### Enabling Default Main Actor Isolation

To enable this feature in your project:

```swift
// In your target settings or Package.swift
// Enable default main actor isolation
```

This means:
- Static variables are automatically protected
- Less `@MainActor` annotations needed
- Safer defaults for app development

## Background Work Offloading

The `@concurrent` attribute explicitly offloads expensive operations to run in parallel.

### Requirements for @concurrent

1. Mark functions with the `@concurrent` attribute
2. Make the containing type `nonisolated`
3. Add `async`/`await` keywords appropriately

```swift
// Example of offloading expensive work
@concurrent
func processLargeDataset(_ data: [DataPoint]) async -> ProcessedResult {
    // Computationally intensive work runs in parallel
    return await performHeavyComputation(data)
}
```

## Best Practices

### When to Use @concurrent

- CPU-intensive calculations
- Image processing
- Data parsing and transformation
- Any work that benefits from parallelization

### When to Stay on Main Actor

- UI updates
- User interaction handling
- Small, quick operations
- Code that accesses UI state

## Migration Path

Swift 6.2 includes migration tooling to help you make the necessary code changes automatically. This allows gradual adoption of these features:

1. Enable the new concurrency mode in your project
2. Let the compiler identify areas that need attention
3. Use the migration tools to update code automatically
4. Review and test the changes

## Practical Examples

### Before Swift 6.2

```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var data: [Item] = []

    func loadData() async {
        // Had to be careful about actor isolation
        let result = await fetchData()
        self.data = result
    }
}
```

### After Swift 6.2

```swift
class ViewModel: ObservableObject {
    @Published var data: [Item] = []

    func loadData() async {
        // Automatically stays on calling actor
        let result = await fetchData()
        self.data = result  // Safe by default
    }

    @concurrent
    func processData(_ items: [Item]) async -> [ProcessedItem] {
        // Explicitly runs in parallel when needed
        return items.map { process($0) }
    }
}
```

## Summary

Swift 6.2's concurrency updates make it easier to write safe, concurrent code by:

1. **Defaulting to single-threaded execution** - Reduces accidental data races
2. **Isolated conformances** - Better protocol support for actor-isolated types
3. **Automatic main actor inference** - Less boilerplate for app targets
4. **Explicit parallelization** - Use `@concurrent` when you need parallel execution

These changes align with Swift's philosophy of progressive disclosure - simple code is safe by default, and you opt into complexity (parallelism) explicitly when needed.

## References

- [Swift Evolution Proposals](https://github.com/apple/swift-evolution)
- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [WWDC 2025 Swift Concurrency Sessions](https://developer.apple.com/wwdc25/)
