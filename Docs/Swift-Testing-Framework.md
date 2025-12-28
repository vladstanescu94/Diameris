# Swift Testing Framework

Apple's modern testing framework introduced in 2024, replacing XCTest for unit tests. Uses macros (`@Test`, `@Suite`) and expression-based assertions (`#expect`, `#require`).

**When to use:** Unit tests for SPM packages and app targets.
**When to use XCTest:** UI tests still require XCTest.

---

## Basic Structure

```swift
import Testing
@testable import MyModule

@Suite("Feature Tests")
struct FeatureTests {

    @Test("Describes what this test verifies")
    func testName() {
        let result = someFunction()
        #expect(result == expectedValue)
    }
}
```

### Key Differences from XCTest

| XCTest | Swift Testing |
|--------|---------------|
| `class MyTests: XCTestCase` | `@Suite struct MyTests` |
| `func testSomething()` | `@Test func something()` |
| `XCTAssertEqual(a, b)` | `#expect(a == b)` |
| `XCTAssertNotNil(x)` | `#expect(x != nil)` or `#require(x)` |
| `XCTFail("message")` | `Issue.record("message")` |

---

## Assertions

### `#expect` - Soft Assertion
Test continues even if assertion fails. Use for most assertions.

```swift
#expect(result == 42)
#expect(array.isEmpty)
#expect(string.contains("hello"))
#expect(value > 0 && value < 100)
```

### `#require` - Hard Assertion
Test stops immediately if assertion fails. Also unwraps optionals.

```swift
// Unwrap optional - test stops if nil
let user = #require(fetchUser())
#expect(user.name == "Vlad")

// Hard assertion - test stops if false
#require(database.isConnected)
```

### Floating Point Comparisons

Don't use `==` for `Decimal` or `Double` - use tolerance:

```swift
// Bad - may fail due to precision
#expect(result == 3000.0)

// Good - tolerance-based comparison
#expect(abs(result - 3000.0) < 0.01)
```

---

## Parameterized Tests

Run the same test with multiple inputs. Much cleaner than XCTest's approach.

### Single Parameter

```swift
@Test("Currency symbols exist", arguments: ["RON", "EUR", "USD"])
func currencySymbols(code: String) {
    let currency = Currency(rawValue: code)
    #expect(currency != nil)
    #expect(!currency!.symbol.isEmpty)
}
```

### Multiple Parameters (Tuple)

```swift
@Test("Savings calculation",
      arguments: [
        (income: Decimal(10000), percentage: 0.25, expected: Decimal(2500)),
        (income: Decimal(8000), percentage: 0.10, expected: Decimal(800)),
        (income: Decimal(5000), percentage: 0.50, expected: Decimal(2500))
      ])
func savingsCalculation(income: Decimal, percentage: Double, expected: Decimal) {
    let result = income * Decimal(percentage)
    #expect(result == expected)
}
```

### Combining Multiple Argument Lists

```swift
@Test("Matrix test", arguments: [1, 2, 3], ["a", "b"])
func matrixTest(number: Int, letter: String) {
    // Runs 6 times: (1,a), (1,b), (2,a), (2,b), (3,a), (3,b)
}
```

---

## Test Organization

### Nested Suites

Group related tests into nested structs:

```swift
@Suite("Calculator Tests")
struct CalculatorTests {

    @Suite("Addition")
    struct Addition {
        @Test("Adds positive numbers")
        func addsPositive() { ... }

        @Test("Adds negative numbers")
        func addsNegative() { ... }
    }

    @Suite("Division")
    struct Division {
        @Test("Divides evenly")
        func dividesEvenly() { ... }

        @Test("Handles division by zero")
        func divisionByZero() { ... }
    }
}
```

### Tags for Filtering

```swift
extension Tag {
    @Tag static var slow: Self
    @Tag static var network: Self
}

@Test("Slow integration test", .tags(.slow))
func slowTest() { ... }

// Run only: swift test --filter .slow
// Exclude: swift test --skip .slow
```

---

## MainActor and Async Tests

### MainActor-Isolated Types

**Critical:** When testing `@MainActor` types (like ViewModels), you must add `@MainActor` to **every nested suite**, not just the parent:

```swift
@Suite("ViewModel Tests")
@MainActor  // Parent suite
struct ViewModelTests {

    @Suite("Navigation")
    @MainActor  // REQUIRED on nested suite too!
    struct Navigation {

        @Test("Advances to next step")
        func advancesStep() {
            let vm = OnboardingViewModel()
            vm.advance()
            #expect(vm.currentStep == .name)
        }
    }
}
```

Without `@MainActor` on nested suites, you'll get:
```
error: Main actor-isolated property 'currentStep' can not be referenced from a nonisolated context
```

### Async Tests

```swift
@Test("Fetches data")
func fetchesData() async {
    let result = await api.fetchData()
    #expect(result.count > 0)
}

@Test("Throws on invalid input")
func throwsOnInvalid() async throws {
    await #expect(throws: ValidationError.self) {
        try await validator.validate(nil)
    }
}
```

---

## Setup and Teardown

### Instance Properties (Per-Test Setup)

```swift
@Suite("Database Tests")
struct DatabaseTests {
    let database: Database  // Fresh instance for each test

    init() {
        database = Database(inMemory: true)
    }
}
```

### Explicit Setup/Teardown

```swift
@Suite("File Tests")
struct FileTests {
    var tempFile: URL!

    init() async throws {
        tempFile = try await createTempFile()
    }

    deinit {
        try? FileManager.default.removeItem(at: tempFile)
    }
}
```

---

## Common Patterns

### Testing Computed Properties

```swift
@Test("Progress calculation")
func progressCalculation() {
    let vm = OnboardingViewModel()

    vm.currentStep = .welcome
    #expect(vm.progress == 0.0)

    vm.currentStep = .transferPlan
    #expect(vm.progress == 1.0)
}
```

### Testing Optional Unwrapping

```swift
@Test("Primary account exists")
func primaryAccountExists() {
    let vm = OnboardingViewModel()

    // Use #require to unwrap and fail fast if nil
    let primary = #require(vm.primaryAccount)
    #expect(primary.isPrimary == true)
}
```

### Testing Array Contents

```swift
@Test("Presets include common values")
func presetsIncludeCommon() {
    let presets = SavingsAllocation.presets

    #expect(presets.contains(0.10))
    #expect(presets.contains(0.25))
}

@Test("Presets are sorted")
func presetsSorted() {
    let presets = SavingsAllocation.presets

    for i in 0..<(presets.count - 1) {
        #expect(presets[i] < presets[i + 1])
    }
}
```

### Testing Codable Conformance

```swift
@Test("Round-trip encoding")
func roundTripEncoding() throws {
    let original = AccountType.emergency

    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(AccountType.self, from: data)

    #expect(decoded == original)
}
```

### Testing Sendable Conformance

```swift
@Test("Can cross actor boundaries")
func canCrossActorBoundaries() async {
    let currency = Currency.eur

    let result = await Task.detached {
        return currency.symbol
    }.value

    #expect(result == "€")
}
```

---

## Gotchas and Tips

### 1. Type Inference in Array Literals

Swift can't infer types in test argument arrays:

```swift
// Error: Cannot infer type
@Test(arguments: [.primary(), .savings()])
func test(account: AccountEntry) { }

// Fix: Explicit type
let accounts: [AccountEntry] = [.primary(), .savings()]
@Test(arguments: accounts)
func test(account: AccountEntry) { }
```

### 2. Locale-Dependent Tests

Formatters produce different output based on locale:

```swift
// Bad - fails on non-US locales
#expect(result == "1,234.56")

// Good - check for key parts
#expect(result.contains("1234") || result.contains("1,234"))
#expect(result.contains("56"))
```

### 3. Decimal Precision

`Decimal` arithmetic can produce tiny precision errors:

```swift
// May produce 3000.000000000000512
let result = Decimal(10000) * Decimal(0.3)

// Bad
#expect(result == 3000)

// Good
#expect(abs(result - 3000) < 0.01)
```

### 4. Import Foundation for Decimal

Test files need `import Foundation` for `Decimal` type:

```swift
import Foundation  // Required for Decimal
import Testing
@testable import MyModule
```

### 5. Partial String Parsing

`Decimal(string:)` parses what it can, doesn't fail on mixed input:

```swift
Decimal(string: "12abc")  // Returns 12, not nil
Decimal(string: "abc12")  // Returns nil
```

---

## Running Tests

### Command Line (SPM Packages)

```bash
# Run all tests in package
cd Packages/Features/Onboarding
xcodebuild test -scheme Onboarding -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Note: `swift test` doesn't work for iOS packages (no UIKit on macOS)
```

### Xcode

- `Cmd+U` - Run all tests
- Click diamond in gutter - Run single test
- Test Navigator (`Cmd+6`) - Browse and run tests

### Filtering

```bash
# Run specific suite
xcodebuild test -only-testing:OnboardingTests/TransferCalculatorTests

# Skip slow tests (if tagged)
swift test --skip .slow
```

---

## File Organization

```
Package/
├── Sources/
│   └── Module/
│       └── Feature.swift
└── Tests/
    └── ModuleTests/
        ├── FeatureTests.swift       # Tests for Feature.swift
        └── AnotherFeatureTests.swift
```

**Naming Convention:**
- Test file: `{SourceFileName}Tests.swift`
- Test suite: `{SourceFileName}Tests`
- Test function: Descriptive name without `test` prefix

---

## Migration from XCTest

```swift
// XCTest
class CalculatorTests: XCTestCase {
    func testAddition() {
        XCTAssertEqual(Calculator.add(2, 3), 5)
    }

    func testDivisionByZero() {
        XCTAssertThrowsError(try Calculator.divide(1, by: 0))
    }
}

// Swift Testing
@Suite("Calculator Tests")
struct CalculatorTests {
    @Test("Addition")
    func addition() {
        #expect(Calculator.add(2, 3) == 5)
    }

    @Test("Division by zero throws")
    func divisionByZero() {
        #expect(throws: MathError.divisionByZero) {
            try Calculator.divide(1, by: 0)
        }
    }
}
```
