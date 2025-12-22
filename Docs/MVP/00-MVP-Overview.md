# Diameris MVP Overview

## Summary

Diameris MVP is a **monthly budget planning app** that transforms a personal Python budget script into a native iOS 26+ application. The MVP focuses on helping users plan their budget after receiving income, track progress toward financial safety (emergency fund), manage loans, and receive intelligent allocation suggestions.

**Primary Use Case:** Monthly budget planning and transfer allocation after payday—not daily transaction logging.

---

## MVP Features

| # | Feature | Description | Doc |
|---|---------|-------------|-----|
| 01 | **Onboarding** | Minimal setup wizard: name, income, core expense prompts | [01-Onboarding.md](./01-Onboarding.md) |
| 02 | **Income** | Monthly net income tracking with currency setting | [02-Income.md](./02-Income.md) |
| 03 | **Expenses** | Monthly and annual expense management | [03-Expenses.md](./03-Expenses.md) |
| 04 | **Categories** | Default, custom, and FM-suggested expense categories | [04-Categories.md](./04-Categories.md) |
| 05 | **Emergency Fund** | 3x income target with progress tracking and allocation priority | [05-EmergencyFund.md](./05-EmergencyFund.md) |
| 06 | **Loans** | User-defined loans with payment and payoff tracking | [06-Loans.md](./06-Loans.md) |
| 07 | **Savings** | Configurable percentage with research-backed defaults | [07-Savings.md](./07-Savings.md) |
| 08 | **Accounts** | Primary account + user-defined additional accounts | [08-Accounts.md](./08-Accounts.md) |
| 09 | **Transfer Planning** | Suggested allocations after payday | [09-TransferPlanning.md](./09-TransferPlanning.md) |
| 10 | **Budget Analysis** | Full optimization via Foundation Models + fallback | [10-BudgetAnalysis.md](./10-BudgetAnalysis.md) |
| 11 | **Settings** | Currency, savings %, and core preferences | [11-Settings.md](./11-Settings.md) |

---

## Core Principles

### 1. Monthly Planning Focus
The app is designed for users who want to **plan their budget once per month** after receiving income. It calculates:
- How much goes to expenses
- How much to save (emergency fund priority, then regular savings)
- How much to allocate to each account
- What remains as flexible spending

### 2. Suggested Allocations Only
MVP does **not** track actual account balances. Instead, it calculates **suggested allocations** based on:
- User's defined income
- Configured expenses
- Savings targets
- Account structure

Actual balance tracking and 3rd party bank integrations are Phase 2+.

### 3. Foundation Models Integration
Where applicable, features leverage Apple's on-device Foundation Models for:
- Category suggestions based on expense names
- Budget optimization recommendations
- Natural language insights

**Critical:** Every FM feature must have a deterministic fallback for devices where Apple Intelligence is unavailable.

### 4. Minimal Onboarding Friction
Users should be productive within minutes. The onboarding wizard:
- Requires only: name, monthly income
- Prompts for (skippable): primary expense categories (food, etc.)
- Allows gradual data entry over time

---

## What's NOT in MVP

| Feature | Reason | Target Phase |
|---------|--------|--------------|
| **Custom Goals** | Emergency fund provides sufficient goal tracking | Phase 2 |
| **Actual Balance Tracking** | Complexity; suggested allocations suffice | Phase 2 |
| **Bank Integrations** | 3rd party APIs require significant effort | Phase 2+ |
| **Scenario Toggles** | Depends on boost/modifier system | Phase 2 |
| **Multiple Income Sources** | Single salary sufficient for MVP | Phase 2 |
| **Widgets** | Nice-to-have, not core functionality | Phase 2 |
| **iPad Optimization** | iPhone-first, iPad later | Phase 2 |
| **iCloud Sync** | Local-only for MVP | Phase 2+ |

---

## User Flow Summary

```
┌─────────────────────────────────────────────────────────────┐
│                     ONBOARDING                               │
│  1. Welcome → Enter name                                     │
│  2. Income → "How much do you receive monthly after taxes?"  │
│  3. Expenses → Quick prompts (food, rent, etc.) [skippable]  │
│  4. Accounts → Define primary + additional accounts          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     MAIN APP                                 │
│                                                              │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌──────────┐       │
│  │Dashboard│  │ Budget  │  │  Goals  │  │Transfers │       │
│  │         │  │         │  │         │  │          │       │
│  │ Summary │  │ Income  │  │Emergency│  │ Payday   │       │
│  │ Health  │  │Expenses │  │  Fund   │  │Allocation│       │
│  │ Insights│  │Categories│  │  Loans │  │Checklist │       │
│  └─────────┘  └─────────┘  └─────────┘  └──────────┘       │
│                                                              │
│                     ┌──────────┐                            │
│                     │ Settings │                            │
│                     └──────────┘                            │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Flow

```
Income (monthly net)
    │
    ├──► Expenses (monthly + annual/12)
    │        │
    │        └──► Remaining = Income - Expenses
    │
    └──► Remaining
            │
            ├──► Savings Allocation (configurable %)
            │        │
            │        ├──► Emergency Fund (priority until 3x income)
            │        │
            │        └──► Regular Savings (after emergency fund complete)
            │
            └──► Flexible Spending (what's left after savings)
```

---

## Technology Stack

| Component | Technology |
|-----------|------------|
| UI Framework | SwiftUI (iOS 26+) |
| Design Language | Apple Liquid Glass |
| Persistence | SwiftData |
| Concurrency | Swift 6.2 (MainActor default) |
| AI/ML | Foundation Models (with fallback) |
| Architecture | SPM Modular (see [Architecture.md](../Architecture.md)) |
| Testing | Swift Testing framework |
| Localization | English + Romanian |

---

## References

- [ProjectDefinition.md](../ProjectDefinition.md) - Original feature scope
- [Architecture.md](../Architecture.md) - Technical architecture
- [DesignGuidelines.md](../DesignGuidelines.md) - UI/UX standards
- [FoundationModels-Using-on-device-LLM.md](../FoundationModels-Using-on-device-LLM.md) - FM integration
- `External Resources/expensesScriptDetailed.py` - Source Python script
