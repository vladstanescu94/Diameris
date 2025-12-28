# Diameris - Project Definition

## Overview

**Diameris** is a personal finance and budget management app for iOS, iPadOS, and future macOS. It reproduces and extends the functionality of a Python budget management script into a native Apple app with the iOS 26 Liquid Glass design language.

**Category:** Finance (`public.app-category.finance`)
**Platforms:** iOS 26+, iPadOS 26+, macOS Tahoe (future)
**Design:** Apple Liquid Glass (WWDC 2025)

---

## Product Vision

Transform a personal Python budget script into a polished, user-friendly iOS app that helps users:
- Track income and expenses (monthly/annual)
- Manage emergency funds and savings goals
- Track loan payments and payoff progress
- Plan bank account transfers
- Get actionable financial insights and recommendations

**Key Differentiator:** Unlike the Python script, the app must NOT hardcode personal assumptions (specific accounts, fixed expense names). Instead, it should be configurable by any user for their own financial situation.

---

## Core Features (MVP)

### 1. Income Management
- Add monthly net income (salary)
- Support multiple income sources (future)
- Currency setting (default: RON, configurable)

### 2. Expense Tracking

**Monthly Expenses:**
- Recurring expenses (rent, subscriptions, food, gas, etc.)
- Category assignment
- Auto-calculate annual totals

**Annual Expenses:**
- One-time or yearly expenses (insurance, taxes, maintenance)
- Spread across months for budget planning

**Categories (configurable):**
- Auto/Transport
- Subscriptions
- Lifestyle
- Housing
- Pets
- Health/Fitness
- Custom categories

### 3. Emergency Fund
- Target: Configurable multiplier of monthly income (default: 3x)
- Track current balance
- Progress visualization
- Smart allocation: prioritize emergency fund before regular savings

### 4. Loan/Debt Tracking
- Track loan balances and monthly payments
- Calculate remaining payments and payoff date
- Show impact of loan completion on monthly budget

### 5. Savings System
- Configurable savings percentage (default: 25%)
- "Savings Boost" mode with multiplier
- Intelligent allocation:
  - Priority 1: Emergency fund completion
  - Priority 2: Regular savings
- Track progress toward financial goals

### 6. Bank Transfer Planning
- Define bank accounts/subaccounts (e.g., Joint, Emergency, Savings, Personal)
- Calculate suggested transfers after payday
- Provide step-by-step transfer instructions

### 7. Budget Analysis
- Income distribution breakdown (expenses, savings, remaining)
- Top expenses ranking
- Category-wise spending analysis
- Financial health indicators (benchmarks)
- Scenario comparisons

### 8. Financial Goals
- Define custom goals with target amounts
- Calculate time-to-goal based on current savings rate
- Visualize progress

---

## Data Model (SwiftData)

```
User
├── income: [Income]
├── expenses: [Expense]
├── categories: [Category]
├── accounts: [Account]
├── loans: [Loan]
├── goals: [Goal]
└── settings: Settings

Income
├── amount: Decimal
├── frequency: Frequency (monthly, biweekly, etc.)
├── name: String
└── isActive: Bool

Expense
├── name: String
├── amount: Decimal
├── frequency: Frequency (monthly, annual, weekly)
├── category: Category?
├── isEnabled: Bool
└── notes: String?

Category
├── name: String
├── icon: String (SF Symbol)
├── color: String (hex)
└── expenses: [Expense]

Account
├── name: String
├── type: AccountType (checking, savings, emergency, joint)
├── currentBalance: Decimal?
└── purpose: String?

Loan
├── name: String
├── totalAmount: Decimal
├── remainingBalance: Decimal
├── monthlyPayment: Decimal
├── interestRate: Decimal?
└── startDate: Date

Goal
├── name: String
├── targetAmount: Decimal
├── currentAmount: Decimal
├── deadline: Date?
└── priority: Int

Settings
├── currency: String
├── emergencyFundMultiplier: Double (default: 3)
├── savingsPercentage: Double (default: 0.25)
├── savingsBoostEnabled: Bool
├── savingsBoostMultiplier: Double (default: 3)
└── locale: String
```

---

## UI Structure

### Tab Bar (Liquid Glass)
1. **Dashboard** - Overview, quick stats, NewMonth flow trigger
2. **Expenses** - Add/edit expenses with categories and subcategories
3. **Insights** - Deep stats, AI-powered tips, scenario analysis

**Note:** Settings will be accessible from Dashboard toolbar, not as a separate tab.

### Key Screens

**Dashboard:**
- Quick summary card (income, expenses, savings, remaining)
- Emergency fund progress ring
- Account balances overview
- This month's expense breakdown
- "New Month" flow (tab bar accessory)

**Expenses:**
- Expense list grouped by category
- Category management (auto, subscriptions, lifestyle, housing, pets, etc.)
- Add/edit expense sheets (Liquid Glass)
- Loans tracked as recurring expenses

**Insights (AI-Enhanced):**
- Spending breakdown by category with percentages
- Personalized tips and recommendations (Foundation Models when available)
- Scenario simulator ("What if I reduce food by 300 RON?")
- Monthly recap and trend analysis
- Financial health benchmarks
- Priority-based action plans

---

## iOS 26 Liquid Glass Implementation

### Navigation
- `NavigationSplitView` for iPad, `NavigationStack` for iPhone
- Floating Liquid Glass toolbar
- `.backgroundExtensionEffect()` for hero images

### Controls
- `.glassEffect()` on custom cards
- `GlassEffectContainer` for grouping related elements
- `.interactive()` for tappable glass elements
- Standard controls get automatic glass treatment

### Sheets
- Partial-height sheets with glass background
- `.navigationZoomTransitionSource/Destination` for morphing

### Tab Bar
- `.tabBarMinimizeBehavior(.onScrollDown)` for collapsing
- `.tabViewBottomAccessory` for contextual controls

---

## Technology Stack

- **UI:** SwiftUI (iOS 26+)
- **Persistence:** SwiftData
- **Concurrency:** Swift 6 (MainActor isolation)
- **Charts:** Swift Charts for visualizations
- **Testing:** Swift Testing framework

---

## Implementation Phases

### Phase 1: Core Data & Basic UI
- [ ] SwiftData models for all entities
- [ ] Basic CRUD for income/expenses
- [ ] Dashboard with summary stats
- [ ] Liquid Glass navigation structure

### Phase 2: Budget Management
- [ ] Category management
- [ ] Monthly/annual expense views
- [ ] Income tracking
- [ ] Budget calculation engine

### Phase 3: Goals & Tracking
- [ ] Emergency fund tracking
- [ ] Loan management
- [ ] Savings goals
- [ ] Progress visualizations

### Phase 4: Intelligence
- [ ] Bank transfer planning
- [ ] Budget analysis & recommendations
- [ ] Scenario comparisons
- [ ] Financial health scoring

### Phase 5: Polish
- [ ] iPad optimization
- [ ] Widgets
- [ ] Charts & visualizations
- [ ] Onboarding flow

---

## Out of Scope (v1)

- Cloud sync / multi-device
- Bank account integration (Plaid, etc.)
- Receipt scanning
- Bill reminders/notifications
- Investment tracking
- Multi-currency conversion
- Shared budgets (couples/family)

---

## Decisions

- **Localization:** English + Romanian from the start
- **App Name:** Diameris (confirmed)
- **Onboarding/Data Entry:** To be defined in feature specs

---

## References

- [Apple Liquid Glass Design](https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/)
- [Build a SwiftUI app with the new design - WWDC25](https://developer.apple.com/videos/play/wwdc2025/323/)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/TechnologyOverviews/adopting-liquid-glass)
