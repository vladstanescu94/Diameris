# Diameris Developer Roadmap

This document tracks implementation progress. **Update this file after completing each task.**

---

## Current Phase: Foundation Setup

### Completed

| Task | Date | Notes |
|------|------|-------|
| Project setup | 2025-12-22 | Xcode project created with SwiftData template |
| Documentation | 2025-12-22 | All MVP specs and architecture docs written |
| DesignSystem package | 2025-12-22 | `Packages/Core/DesignSystem/` with colors, spacing, corner radii, icon sizes, glass components |
| Brand colors | 2025-12-22 | AccentPrimary (magenta), AccentSecondary (teal) in Assets.xcassets |
| DesignSystem linked | 2025-12-22 | Package added to Xcode project, verified on device |

### In Progress

| Task | Notes |
|------|-------|
| - | - |

### Next Up

| Priority | Task | Reference |
|----------|------|-----------|
| 1 | Create Domain/Entities package | Pure Swift business models |
| 2 | Create Core/Utilities package | Extensions, formatters, Currency type |
| 3 | Clean up template code | Remove Item.swift, update ContentView |

---

## MVP Feature Progress

Based on [MVP Overview](./MVP/00-MVP-Overview.md)

| # | Feature | Status | Spec | Notes |
|---|---------|--------|------|-------|
| 01 | Onboarding | Not Started | [01-Onboarding.md](./MVP/01-Onboarding.md) | |
| 02 | Income | Not Started | [02-Income.md](./MVP/02-Income.md) | |
| 03 | Expenses | Not Started | [03-Expenses.md](./MVP/03-Expenses.md) | |
| 04 | Categories | Not Started | [04-Categories.md](./MVP/04-Categories.md) | |
| 05 | Emergency Fund | Not Started | [05-EmergencyFund.md](./MVP/05-EmergencyFund.md) | |
| 06 | Loans | Not Started | [06-Loans.md](./MVP/06-Loans.md) | |
| 07 | Savings | Not Started | [07-Savings.md](./MVP/07-Savings.md) | |
| 08 | Accounts | Not Started | [08-Accounts.md](./MVP/08-Accounts.md) | |
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
| Domain | Entities | Not Started | Pure Swift business models |
| Domain | UseCases | Not Started | Business logic |
| Domain | Repositories | Not Started | Protocol definitions |
| Platform | Persistence | Not Started | SwiftData implementations |
| Features | Dashboard | Not Started | |
| Features | Budget | Not Started | |
| Features | Goals | Not Started | |
| Features | Transfers | Not Started | |
| Features | Settings | Not Started | |

### App Infrastructure

| Component | Status | Notes |
|-----------|--------|-------|
| DependencyContainer | Not Started | Manual DI composition root |
| AppRouter | Not Started | Navigation state management |
| MainTabView | Not Started | Tab bar with 5 tabs |

---

## Technical Debt & Notes

- Template `Item.swift` model needs removal
- Template `ContentView.swift` needs replacement with actual app UI

---

## How to Update This File

After completing a task:
1. Move it from "Next Up" or "In Progress" to "Completed" with date
2. Update the relevant status in MVP Feature Progress or Architecture Progress
3. Add any technical debt or notes discovered during implementation
