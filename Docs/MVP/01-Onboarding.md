# Onboarding

## Overview

The onboarding flow introduces new users to Diameris with minimal friction. It collects essential information needed to calculate budget allocations while allowing users to skip optional steps and fill in details later.

**Design Philosophy:** Get users to a useful state within 2-3 minutes. Required information is minimal; everything else can be added gradually.

---

## User Stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| New user | Complete setup quickly | I can start using the app immediately |
| New user | Skip steps I'm not ready for | I don't feel overwhelmed on first launch |
| New user | Understand why data is needed | I feel comfortable providing financial info |
| Returning user | See my setup is remembered | I don't repeat onboarding |

---

## Onboarding Flow

### Step 1: Welcome
**Purpose:** Establish trust and set expectations.

```
┌─────────────────────────────────────┐
│                                     │
│         [App Icon/Logo]             │
│                                     │
│     Welcome to Diameris             │
│                                     │
│   Your personal budget planner      │
│                                     │
│   Let's set up your budget in       │
│   just a few steps.                 │
│                                     │
│        [Get Started]                │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Liquid Glass card for welcome message
- Simple, warm illustration or icon
- Single primary CTA button

---

### Step 2: Your Name
**Purpose:** Personalization.
**Required:** Yes

```
┌─────────────────────────────────────┐
│                                     │
│     What should we call you?        │
│                                     │
│   ┌─────────────────────────────┐   │
│   │  Your name                  │   │
│   └─────────────────────────────┘   │
│                                     │
│   We'll use this to personalize     │
│   your experience.                  │
│                                     │
│        [Continue]                   │
│                                     │
└─────────────────────────────────────┘
```

**Validation:**
- Minimum 1 character
- Maximum 50 characters
- Trimmed whitespace

**Future (Phase 2+):** Sign in with Apple / Google options.

---

### Step 3: Monthly Income
**Purpose:** Core calculation baseline.
**Required:** Yes

```
┌─────────────────────────────────────┐
│                                     │
│   How much do you receive each      │
│   month after taxes?                │
│                                     │
│   ┌─────────────────────────────┐   │
│   │  [Currency] │    Amount     │   │
│   │    RON      │   14,303      │   │
│   └─────────────────────────────┘   │
│                                     │
│   This is your net monthly income   │
│   (salary, after all deductions).   │
│                                     │
│        [Continue]                   │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Currency picker (default: RON, also support EUR, USD)
- Numeric keyboard for amount
- Formatted display with thousands separator
- Helpful explainer text

**Validation:**
- Amount > 0
- Reasonable maximum (e.g., 1,000,000)

---

### Step 4: Essential Expenses (Skippable)
**Purpose:** Quick expense setup for core categories.
**Required:** No (skippable)

```
┌─────────────────────────────────────┐
│                                     │
│   Let's estimate your main          │
│   expenses                          │
│                                     │
│   🍽️ Food & Groceries               │
│   ┌─────────────────────────────┐   │
│   │  RON        │   3,000       │   │
│   └─────────────────────────────┘   │
│                                     │
│   🏠 Rent / Housing                 │
│   ┌─────────────────────────────┐   │
│   │  RON        │   0           │   │
│   └─────────────────────────────┘   │
│                                     │
│   ⛽ Transportation                  │
│   ┌─────────────────────────────┐   │
│   │  RON        │   300         │   │
│   └─────────────────────────────┘   │
│                                     │
│   [Skip for now]    [Continue]      │
│                                     │
└─────────────────────────────────────┘
```

**Categories Prompted:**
1. **Food & Groceries** - High universal relevance
2. **Rent / Housing** - Major expense category
3. **Transportation** - Common recurring cost

**UI Notes:**
- Pre-filled with 0 or reasonable defaults
- "Skip for now" clearly visible
- Each field optional (0 is valid)
- Expenses created as monthly frequency

---

### Step 5: Accounts Setup
**Purpose:** Define where money goes.
**Required:** Primary account only

```
┌─────────────────────────────────────┐
│                                     │
│   Where does your income arrive?    │
│                                     │
│   PRIMARY ACCOUNT                   │
│   ┌─────────────────────────────┐   │
│   │  Main Checking              │   │
│   └─────────────────────────────┘   │
│   This is where your salary lands.  │
│                                     │
│   ─────────────────────────────────│
│                                     │
│   Do you have other accounts?       │
│                                     │
│   [+ Add Account]                   │
│                                     │
│   Examples: Savings, Emergency,     │
│   Joint account, etc.               │
│                                     │
│   [Skip for now]    [Continue]      │
│                                     │
└─────────────────────────────────────┘
```

**Add Account Flow:**
```
┌─────────────────────────────────────┐
│   Add Account                       │
│                                     │
│   Name                              │
│   ┌─────────────────────────────┐   │
│   │  Emergency Fund             │   │
│   └─────────────────────────────┘   │
│                                     │
│   Purpose (optional)                │
│   ┌─────────────────────────────┐   │
│   │  3x salary safety net       │   │
│   └─────────────────────────────┘   │
│                                     │
│   [Cancel]          [Add]           │
└─────────────────────────────────────┘
```

**UI Notes:**
- Primary account name editable (default: "Main Checking")
- Additional accounts optional
- Quick-add suggestions: "Emergency", "Savings", "Joint"

---

### Step 6: Completion
**Purpose:** Confirm setup and transition to main app.

```
┌─────────────────────────────────────┐
│                                     │
│         ✓ You're all set!           │
│                                     │
│   Hi [Name], your budget is ready.  │
│                                     │
│   ┌─────────────────────────────┐   │
│   │  Monthly Income: 14,303 RON │   │
│   │  Expenses: 3,300 RON        │   │
│   │  Accounts: 2                │   │
│   └─────────────────────────────┘   │
│                                     │
│   You can add more details anytime  │
│   in the Budget tab.                │
│                                     │
│        [Start Planning]             │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Summary card showing what was configured
- Encouraging completion message
- Clear CTA to enter main app

---

## Data Model

### Entities Created During Onboarding

```swift
// User profile
struct UserProfile {
    var name: String
    var currency: Currency  // Default: RON
    var onboardingCompleted: Bool
    var createdAt: Date
}

// Income (one created)
struct Income {
    var id: UUID
    var name: String  // Default: "Salary"
    var amount: Decimal
    var frequency: Frequency  // .monthly
    var isActive: Bool
}

// Expenses (0-3 created from quick setup)
struct Expense {
    var id: UUID
    var name: String
    var amount: Decimal
    var frequency: Frequency  // .monthly
    var categoryID: UUID?
    var isEnabled: Bool
}

// Accounts (1+ created)
struct Account {
    var id: UUID
    var name: String
    var purpose: String?
    var isPrimary: Bool
    var sortOrder: Int
}
```

See [Architecture.md](../Architecture.md) for full entity definitions.

---

## UI/UX Notes

### Design Principles
- **Progress indicator:** Show step X of 6
- **Back navigation:** Allow going back to previous steps
- **Keyboard handling:** Auto-advance focus, dismiss on continue
- **Liquid Glass:** Use for cards and primary CTAs
- **Animations:** Subtle transitions between steps

### Accessibility
- VoiceOver labels for all inputs
- Dynamic Type support
- Sufficient contrast over glass backgrounds

### Responsive Behavior
- iPhone: Full-screen flow
- iPad: Centered card layout (future)

---

## Implementation Notes

### State Management
- Onboarding state stored in `UserDefaults` or SwiftData
- `onboardingCompleted` flag prevents re-showing
- Partial completion should be resumable

### Validation
- Real-time validation with inline errors
- Disable "Continue" until valid
- Clear error messages

### Analytics (Future)
- Track step completion rates
- Identify drop-off points
- A/B test different flows

---

## Out of Scope (MVP)

| Feature | Reason |
|---------|--------|
| Sign in with Apple/Google | Auth complexity; local-only MVP |
| Import from other apps | No standard format; manual entry first |
| Currency conversion | Single currency per user for MVP |
| Loan setup in onboarding | Keep onboarding minimal; loans added later |
| Emergency fund target customization | Use default 3x; customizable in settings |

---

## Open Questions

1. **Default currency detection:** Should we detect locale and suggest currency, or always default to RON?
2. **Skip all:** Should there be a "Skip entire onboarding" option for power users?
3. **Re-onboarding:** How do users reset their data and start over?

---

## References

- [DesignGuidelines.md](../DesignGuidelines.md) - Liquid Glass, typography, spacing
- [08-Accounts.md](./08-Accounts.md) - Account model details
- [02-Income.md](./02-Income.md) - Income model details
