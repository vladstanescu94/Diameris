# Foundation Models: Using Apple's On-Device LLM

## Overview

Foundation Models is an Apple framework enabling developers to integrate on-device large language models that power Apple Intelligence. The framework provides access to a ~3 billion parameter language model for text generation, understanding, summarization, entity extraction, and structured data generation—all without cloud connectivity.

**Requirements:**
- iOS 26+, iPadOS 26+, macOS 26+
- Apple Intelligence enabled on device
- Apple Intelligence-compatible hardware

**Benefits:**
- **Offline capable** - Works without internet connection
- **Free inference** - No API costs or usage limits
- **Privacy-preserving** - All processing happens on-device
- **Low latency** - ~0.6ms per prompt token, 30 tokens/second generation

**Model capabilities:**
- Text summarization
- Entity extraction
- Structured data generation
- Short dialog
- Content refinement

**Not designed for:**
- General knowledge chatbot
- Extensive creative writing
- Complex reasoning tasks

---

## Getting Started

### Check Model Availability

Before using the model, verify availability through `SystemLanguageModel.default`. The model may be unavailable due to device ineligibility, disabled Apple Intelligence, or model preparation states.

```swift
import FoundationModels

let model = SystemLanguageModel.default

switch model.availability {
case .available:
    // Ready to use
case .unavailable(let reason):
    switch reason {
    case .deviceNotEligible:
        // Device doesn't support Apple Intelligence
    case .appleIntelligenceDisabled:
        // User has disabled Apple Intelligence
    case .modelNotReady:
        // Model is still being prepared
    @unknown default:
        break
    }
}
```

### Create a Session

Use `LanguageModelSession` to interact with the model:

```swift
// Basic session
let session = LanguageModelSession()

// Session with instructions
let session = LanguageModelSession(
    instructions: "You are a helpful financial assistant. Be concise and accurate."
)
```

**Important:** Sessions have a 4,096 token context limit. For large tasks, break work into multiple sessions.

---

## Basic Usage

### Instructions

Instructions steer model behavior for your specific application. Effective instructions specify:
- The model's role
- Desired actions
- Style preferences
- Safety parameters

```swift
let session = LanguageModelSession(
    instructions: """
    You are a budget analysis assistant.
    - Provide concise, actionable insights
    - Use clear, professional language
    - Focus on factual financial data
    - Never provide investment advice
    """
)
```

### Prompts

Prompts should be:
- Conversational in tone
- Focused on a single, specific task
- Clear about desired output format and length

### Generation

Call `session.respond(to:)` asynchronously to generate responses:

```swift
let response = try await session.respond(to: "Summarize my spending this month")
print(response.content) // The generated text
```

### Generation Options

Customize generation with `GenerationOptions`:

```swift
let options = GenerationOptions(
    temperature: 0.7,  // 0.0-2.0, higher = more creative
    maximumTokenCount: 500
)

let response = try await session.respond(
    to: prompt,
    options: options
)
```

---

## Guided Generation

Guided generation returns structured Swift data instead of raw text, eliminating fragile string parsing.

### @Generable Macro

Define custom types for structured output:

```swift
import FoundationModels

@Generable
struct ExpenseClassification {
    let category: String
    let confidence: Double
    let reasoning: String
}
```

Generate structured responses:

```swift
let response = try await session.respond(
    to: "Classify this expense: 'Starbucks $5.50'",
    generating: ExpenseClassification.self
)

print(response.content.category)    // "Food & Dining"
print(response.content.confidence)  // 0.95
```

### @Guide Macro

Constrain field values with descriptions and validation:

```swift
@Generable
struct ParsedExpense {
    @Guide(description: "The merchant or vendor name")
    let merchant: String

    @Guide(description: "The expense amount in the user's currency")
    let amount: Double

    @Guide(description: "Confidence score from 0 to 1", .range(0...1))
    let confidence: Double

    @Guide(description: "The expense category", .anyOf([
        "Food & Dining",
        "Transportation",
        "Shopping",
        "Entertainment",
        "Bills & Utilities",
        "Other"
    ]))
    let category: String
}
```

### Nested Types and Enums

Create hierarchical structures:

```swift
@Generable
struct BudgetSummary {
    @Guide(description: "Summary title")
    let title: String

    @Guide(description: "List of expense breakdowns by category")
    let categories: [CategoryBreakdown]

    @Guide(description: "Overall assessment")
    let assessment: Assessment
}

@Generable
struct CategoryBreakdown {
    let name: String
    let totalAmount: Double
    let percentageOfBudget: Double
}

@Generable
enum Assessment: String, Codable {
    case underBudget
    case onTrack
    case overBudget
}
```

---

## Tool Calling

Tools allow the model to execute custom code, access external data, or integrate other frameworks.

### Implement the Tool Protocol

```swift
struct ExpenseLookupTool: Tool {
    let expenseRepository: ExpenseRepositoryProtocol

    var name: String { "lookupExpenses" }
    var description: String {
        "Fetches expenses for a given time period and optional category"
    }

    @Generable
    struct Arguments {
        @Guide(description: "Start date for the query (ISO 8601)")
        let startDate: String

        @Guide(description: "End date for the query (ISO 8601)")
        let endDate: String

        @Guide(description: "Optional category filter")
        let category: String?
    }

    func call(arguments: Arguments) async throws -> ToolOutput {
        let expenses = try await expenseRepository.fetch(
            from: arguments.startDate,
            to: arguments.endDate,
            category: arguments.category
        )

        let summary = expenses.map { "\($0.name): \($0.amount)" }
            .joined(separator: "\n")

        return ToolOutput(summary)
    }
}
```

### Provide Tools to Session

```swift
let session = LanguageModelSession(
    instructions: "You help users understand their spending.",
    tools: [ExpenseLookupTool(expenseRepository: repository)]
)

// The model will automatically use tools when appropriate
let response = try await session.respond(
    to: "How much did I spend on food last month?"
)
```

---

## Streaming

Foundation Models uses snapshot-based streaming (not delta-based). Properties populate as generation progresses.

### Stream Responses

```swift
let stream = session.streamResponse(
    to: prompt,
    generating: BudgetSummary.self
)

for try await snapshot in stream {
    // Properties are optional until fully generated
    if let title = snapshot.content?.title {
        print("Title: \(title)")
    }
    if let categories = snapshot.content?.categories {
        print("Categories loaded: \(categories.count)")
    }
}
```

### Stream Plain Text

```swift
let stream = session.streamResponse(to: prompt)

for try await snapshot in stream {
    print(snapshot.content) // Partial text so far
}
```

---

## Best Practices

### Context Limits
- Sessions support 4,096 tokens maximum
- Break large tasks into multiple sessions
- Reuse sessions for multi-turn conversations to preserve context

### Prompt Engineering
- Be specific about desired output format
- Include examples when possible
- Constrain output length explicitly
- Use `@Guide` descriptions liberally

### Performance
- Monitor with Xcode Instruments
- Access `session.transcript` for debugging
- Consider caching common operations

### Error Handling
- Always check model availability first
- Handle unavailability gracefully with fallback UI
- Provide manual input alternatives

---

## References

- [Foundation Models | Apple Developer Documentation](https://developer.apple.com/documentation/FoundationModels)
- [Apple Foundation Models Framework Announcement](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/)
- [Apple ML Research - Foundation Models 2025](https://machinelearning.apple.com/research/apple-foundation-models-2025-updates)
- [Exploring the Foundation Models Framework](https://www.createwithswift.com/exploring-the-foundation-models-framework/)
- [The Ultimate Guide to Foundation Models](https://azamsharp.com/2025/06/18/the-ultimate-guide-to-the-foundation-models-framework.html)
