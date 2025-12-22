# Diameris AI Features - Pre-MVP Ideas

> **Status:** Pre-MVP brainstorming document
>
> These are preliminary ideas for potential AI features using Apple's Foundation Models framework. **Real feature decisions will be made during MVP development.** This document serves as a reference for what's technically possible.

---

## Foundation Models Overview

Apple's Foundation Models framework (iOS 26+) provides access to a ~3B parameter on-device LLM. See `FoundationModels-Using-on-device-LLM.md` for full API documentation.

**Key benefits for Diameris:**
- Free inference (no API costs)
- Works offline
- Privacy-preserving (no data leaves device)
- Swift-native with `@Generable` for structured output

**Limitations:**
- Requires Apple Intelligence-enabled device
- Not all users will have access
- 4,096 token context limit per session
- Not suitable for complex financial analysis

---

## Potential Feature Ideas

### 1. Smart Expense Entry

**Concept:** Allow users to enter expenses in natural language.

```
User input: "Paid 150 RON for electricity yesterday"

Extracted:
- Amount: 150 RON
- Category: Bills & Utilities
- Date: [yesterday's date]
- Merchant: Electricity provider
```

**Technical approach:**
```swift
@Generable
struct ParsedExpenseInput {
    @Guide(description: "The expense amount as a number")
    let amount: Double

    @Guide(description: "The currency code if mentioned, otherwise nil")
    let currency: String?

    @Guide(description: "Suggested category for this expense")
    let suggestedCategory: String

    @Guide(description: "Merchant or payee name if identifiable")
    let merchant: String?

    @Guide(description: "Relative or absolute date mentioned")
    let dateDescription: String?
}
```

---

### 2. Auto-Categorization Suggestions

**Concept:** Suggest categories based on expense name/merchant.

```
User adds: "Starbucks - $5.50"
Suggestion: Food & Dining (95% confidence)
```

**Notes:**
- Should work with user's custom categories
- Present as suggestion, not automatic assignment
- Include confidence score for UX decisions

---

### 3. Transaction Description Parsing

**Concept:** Parse cryptic bank statement descriptions.

```
Input: "POS PURCHASE AMZN MKTP US*2X7K9"
Output: "Amazon Marketplace" → Shopping
```

**Use case:** Bulk import from bank statements where descriptions are abbreviated or encoded.

---

### 4. Budget Insight Generation

**Concept:** Generate natural language summaries of spending patterns.

```
"This month you spent 23% more on dining compared to last month.
Your largest expense category was Transportation at 1,200 RON."
```

**Notes:**
- App calculates the data, model generates readable summary
- Keep summaries short (model works best with concise output)
- Could power a "monthly recap" feature

---

## Technical Considerations

### Architecture Placement

If implemented, AI features would likely live in:
- `Packages/Platform/AIServices/` - Foundation Models wrapper
- Feature modules consume via protocol abstraction

### Availability Handling

```swift
// Always provide non-AI fallback
if SystemLanguageModel.default.availability == .available {
    // Show AI-powered quick entry
} else {
    // Show standard form entry
}
```

### Privacy

- All processing on-device
- No expense data sent to external services
- Aligns with finance app privacy expectations

---

## Decision: TBD During MVP

These features are **not committed for MVP**. Decisions to implement will consider:

1. Does it provide meaningful value over standard UI?
2. Is the model accurate enough for financial data?
3. How many users have Apple Intelligence access?
4. Development effort vs. impact

---

## References

- `FoundationModels-Using-on-device-LLM.md` - API documentation
- `ProjectDefinition.md` - Core MVP features
