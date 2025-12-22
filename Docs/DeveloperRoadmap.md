# Diameris Developer Roadmap

This document tracks implementation progress. **Update this file after completing each task.**

---

## Current Phase: MVP Feature Development

### Completed

| Task | Date | Notes |
|------|------|-------|
| Project setup | 2025-12-22 | Xcode project created with SwiftData template |
| Documentation | 2025-12-22 | All MVP specs and architecture docs written |
| DesignSystem package | 2025-12-22 | `Packages/Core/DesignSystem/` with colors, spacing, corner radii, icon sizes, glass components |
| Brand colors | 2025-12-22 | AccentPrimary (magenta), AccentSecondary (teal) in Assets.xcassets |
| DesignSystem linked | 2025-12-22 | Package added to Xcode project, verified on device |
| Onboarding package | 2025-12-22 | `Packages/Features/Onboarding/` - 5-screen flow with SwiftData persistence |
| SwiftData models | 2025-12-22 | UserProfile, Income, Expense, Account models in Onboarding package |
| MainTabView | 2025-12-22 | Placeholder tab bar with Dashboard, Budget, Goals, Transfers tabs |
| DevDebugView | 2025-12-22 | DEBUG-only dev tools tab for resetting onboarding |
| Template cleanup | 2025-12-22 | Removed Item.swift, ContentView.swift; updated DiamerisApp.swift |
| Onboarding integrated | 2025-12-22 | Package added to Xcode, tested and working |

### In Progress

| Task | Notes |
|------|-------|
| Onboarding refinements | UI/UX improvements based on testing |

### Next Up

| Priority | Task | Reference |
|----------|------|-----------|
| 1 | Implement Dashboard feature | Main summary view after onboarding |
| 3 | Implement Budget feature | Income/expense management |

---

## MVP Feature Progress

Based on [MVP Overview](./MVP/00-MVP-Overview.md)

| # | Feature | Status | Spec | Notes |
|---|---------|--------|------|-------|
| 01 | Onboarding | In Progress | [01-Onboarding.md](./MVP/01-Onboarding.md) | Working, refinements in progress |
| 02 | Income | Not Started | [02-Income.md](./MVP/02-Income.md) | Basic model created in onboarding |
| 03 | Expenses | Not Started | [03-Expenses.md](./MVP/03-Expenses.md) | Basic model created in onboarding |
| 04 | Categories | Not Started | [04-Categories.md](./MVP/04-Categories.md) | |
| 05 | Emergency Fund | Not Started | [05-EmergencyFund.md](./MVP/05-EmergencyFund.md) | |
| 06 | Loans | Not Started | [06-Loans.md](./MVP/06-Loans.md) | |
| 07 | Savings | Not Started | [07-Savings.md](./MVP/07-Savings.md) | |
| 08 | Accounts | Not Started | [08-Accounts.md](./MVP/08-Accounts.md) | Basic model created in onboarding |
| 09 | Transfer Planning | Not Started | [09-TransferPlanning.md](./MVP/09-TransferPlanning.md) | |
| 10 | Budget Analysis | Not Started | [10-BudgetAnalysis.md](./MVP/10-BudgetAnalysis.md) | |
| 11 | Settings | Not Started | [11-Settings.md](./MVP/11-Settings.md) | |

**Status Legend:** Not Started → In Progress → Done

---

## Architecture Progress

Based on [Architecture.md](./Architecture.md)

### Packages

| Layer | Package | Status | Notes |
|-------|---------|--------|-------|
| Core | DesignSystem | Done | Colors, spacing, corner radii, icon sizes, glass helpers |
| Core | Utilities | Not Started | Extensions, formatters |
| Core | SharedUI | Not Started | Reusable view components |
| Domain | Entities | Not Started | Pure Swift business models (may extract from Onboarding later) |
| Domain | UseCases | Not Started | Business logic |
| Domain | Repositories | Not Started | Protocol definitions |
| Platform | Persistence | Not Started | SwiftData implementations |
| Features | Onboarding | Done | 5-screen flow, SwiftData models, ViewModel |
| Features | Dashboard | Not Started | Placeholder view created |
| Features | Budget | Not Started | Placeholder view created |
| Features | Goals | Not Started | Placeholder view created |
| Features | Transfers | Not Started | Placeholder view created |
| Features | Settings | Not Started | |

### App Infrastructure

| Component | Status | Notes |
|-----------|--------|-------|
| DependencyContainer | Not Started | Manual DI composition root |
| AppRouter | Not Started | Navigation state management |
| MainTabView | Done | 4 tabs + Dev tab (DEBUG only) |
| Onboarding flow | Done | Forward-only, UserDefaults flag, SwiftData persistence |

---

## Technical Debt & Notes

- SwiftData models currently live in Onboarding package; may extract to Domain layer when patterns emerge
- Currency enum in Onboarding; may move to shared Utilities package later

---

## How to Update This File

After completing a task:
1. Move it from "Next Up" or "In Progress" to "Completed" with date
2. Update the relevant status in MVP Feature Progress or Architecture Progress
3. Add any technical debt or notes discovered during implementation
