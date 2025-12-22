# Settings

## Overview

Settings provides access to app configuration, user preferences, and data management. It centralizes options that affect calculations (like savings percentage and emergency fund multiplier) and personalizes the experience (like currency and appearance).

**Key Principle:** Keep settings minimal for MVP. Only include options that meaningfully impact the user experience or calculations.

---

## User Stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| User | Change my currency | Amounts are in my local currency |
| User | Adjust my savings percentage | I control how much I save |
| User | Set emergency fund multiplier | My target matches my risk tolerance |
| User | Update my profile | My name is correct |
| User | Manage my accounts | I can add/edit/remove accounts |
| User | Manage categories | I can customize expense categories |
| User | Export or reset data | I have control over my data |

---

## Settings Structure

### Settings Model

```swift
struct AppSettings: Codable {
    // Profile
    var userName: String

    // Currency
    var currency: Currency

    // Savings
    var savingsPercentage: Double  // 0.05 to 0.50

    // Emergency Fund
    var emergencyFundMultiplier: Double  // 1 to 12

    // Appearance (future)
    var colorScheme: ColorScheme?  // nil = system

    // Data
    var lastBackupDate: Date?
}

extension AppSettings {
    static let `default` = AppSettings(
        userName: "",
        currency: .ron,
        savingsPercentage: 0.25,
        emergencyFundMultiplier: 3.0,
        colorScheme: nil,
        lastBackupDate: nil
    )
}
```

---

## Settings Categories

### 1. Profile

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| Name | String | "" | User's display name |

### 2. Currency

| Setting | Type | Default | Options |
|---------|------|---------|---------|
| Currency | Enum | RON | RON, EUR, USD |

### 3. Budget Settings

| Setting | Type | Default | Range |
|---------|------|---------|-------|
| Savings Percentage | Double | 25% | 5% - 50% |
| Emergency Fund Multiplier | Double | 3x | 1x - 12x |

### 4. Data Management

| Setting | Type | Description |
|---------|------|-------------|
| Accounts | Link | Manage bank accounts |
| Categories | Link | Manage expense categories |
| Export Data | Action | Export budget data |
| Reset Data | Action | Delete all data and restart |

### 5. About

| Setting | Type | Description |
|---------|------|-------------|
| App Version | Display | Current version number |
| Privacy Policy | Link | Open privacy policy |
| Support | Link | Contact support / GitHub |

---

## UI/UX

### Settings Screen

```
┌─────────────────────────────────────┐
│  Settings                           │
│                                     │
│  PROFILE                            │
│  ┌─────────────────────────────┐    │
│  │ 👤 Name                     │    │
│  │    Vlad                   > │    │
│  └─────────────────────────────┘    │
│                                     │
│  PREFERENCES                        │
│  ┌─────────────────────────────┐    │
│  │ 💱 Currency                 │    │
│  │    RON                    > │    │
│  ├─────────────────────────────┤    │
│  │ 💰 Savings Rate             │    │
│  │    25%                    > │    │
│  ├─────────────────────────────┤    │
│  │ 🛡️ Emergency Fund Target    │    │
│  │    3× monthly income      > │    │
│  └─────────────────────────────┘    │
│                                     │
│  MANAGE                             │
│  ┌─────────────────────────────┐    │
│  │ 🏦 Accounts                 │    │
│  │    5 accounts             > │    │
│  ├─────────────────────────────┤    │
│  │ 🏷️ Categories               │    │
│  │    8 categories           > │    │
│  └─────────────────────────────┘    │
│                                     │
│  DATA                               │
│  ┌─────────────────────────────┐    │
│  │ 📤 Export Data              │    │
│  │    Save a copy            > │    │
│  ├─────────────────────────────┤    │
│  │ 🗑️ Reset All Data           │    │
│  │    Start fresh            > │    │
│  └─────────────────────────────┘    │
│                                     │
│  ABOUT                              │
│  ┌─────────────────────────────┐    │
│  │ ℹ️ Version                  │    │
│  │    1.0.0 (1)                │    │
│  ├─────────────────────────────┤    │
│  │ 📄 Privacy Policy         > │    │
│  ├─────────────────────────────┤    │
│  │ 💬 Support                > │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

### Currency Picker

```
┌─────────────────────────────────────┐
│  ← Currency                         │
│                                     │
│  Select your currency               │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ ● RON - Romanian Leu        │    │
│  │   lei                       │    │
│  ├─────────────────────────────┤    │
│  │ ○ EUR - Euro                │    │
│  │   €                         │    │
│  ├─────────────────────────────┤    │
│  │ ○ USD - US Dollar           │    │
│  │   $                         │    │
│  └─────────────────────────────┘    │
│                                     │
│  Currency affects how amounts       │
│  are displayed throughout the app.  │
│                                     │
└─────────────────────────────────────┘
```

### Savings Rate Setting

```
┌─────────────────────────────────────┐
│  ← Savings Rate                     │
│                                     │
│  What percentage of your available  │
│  income should go to savings?       │
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │  ──────────────●──────────  │    │
│  │             25%             │    │
│  │                             │    │
│  │  5%                    50%  │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  Monthly savings: 2,751 RON         │
│  Annual savings: 33,012 RON         │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  💡 RECOMMENDATION                  │
│                                     │
│  Financial experts recommend        │
│  saving 20-30% of income.           │
│                                     │
│  • 10-15%: Good start               │
│  • 15-20%: Solid rate               │
│  • 20-30%: Building wealth          │
│  • 30%+: Aggressive saver           │
│                                     │
└─────────────────────────────────────┘
```

### Emergency Fund Multiplier

```
┌─────────────────────────────────────┐
│  ← Emergency Fund Target            │
│                                     │
│  How many months of income should   │
│  your emergency fund cover?         │
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │     ○   ○   ●   ○   ○       │    │
│  │     1   2   3   6   12      │    │
│  │                             │    │
│  │     3 months selected       │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  Target: 42,909 RON                 │
│  (3 × 14,303 RON monthly income)    │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  💡 RECOMMENDATION                  │
│                                     │
│  • 1-2 months: Minimal buffer       │
│  • 3 months: Standard recommendation│
│  • 6 months: Conservative approach  │
│  • 12 months: Maximum security      │
│                                     │
│  Most financial advisors recommend  │
│  3-6 months of expenses saved.      │
│                                     │
└─────────────────────────────────────┘
```

### Reset Data Confirmation

```
┌─────────────────────────────────────┐
│                                     │
│  ⚠️ Reset All Data?                 │
│                                     │
│  This will permanently delete:      │
│                                     │
│  • All income entries               │
│  • All expenses                     │
│  • All accounts                     │
│  • Emergency fund progress          │
│  • Loan information                 │
│  • Custom categories                │
│                                     │
│  This action cannot be undone.      │
│                                     │
│  ┌───────────────────────────────┐  │
│  │         Cancel                │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌───────────────────────────────┐  │
│  │      Reset Everything         │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

---

## Implementation Notes

### Storage

Settings are stored using SwiftData or UserDefaults:

```swift
// For simple settings: UserDefaults via @AppStorage
@AppStorage("currency") var currency: String = Currency.ron.rawValue
@AppStorage("savingsPercentage") var savingsPercentage: Double = 0.25
@AppStorage("emergencyFundMultiplier") var emergencyFundMultiplier: Double = 3.0

// For complex settings: SwiftData
@Model
final class SettingsEntity {
    var userName: String
    var currency: String
    var savingsPercentage: Double
    var emergencyFundMultiplier: Double
    var lastBackupDate: Date?
}
```

### Settings Repository

```swift
protocol SettingsRepositoryProtocol: Sendable {
    func fetch() async throws -> AppSettings
    func save(_ settings: AppSettings) async throws
    func reset() async throws
}
```

### Impact on Calculations

When settings change, recalculate affected values:

| Setting Changed | Recalculate |
|-----------------|-------------|
| Currency | All displayed amounts (formatting only) |
| Savings Percentage | Savings allocation, transfer amounts |
| Emergency Fund Multiplier | Emergency fund target, progress |

---

## Data Export

### Export Format

MVP export as JSON:

```swift
struct ExportData: Codable {
    let exportDate: Date
    let appVersion: String
    let settings: AppSettings
    let income: [Income]
    let expenses: [Expense]
    let categories: [Category]
    let accounts: [Account]
    let loans: [Loan]
    let emergencyFund: EmergencyFund?
}
```

### Export Flow

1. User taps "Export Data"
2. App generates JSON file
3. Share sheet appears
4. User saves to Files or shares

---

## Validation Rules

| Setting | Validation | Error Message |
|---------|------------|---------------|
| Name | 1-50 characters | "Name must be between 1 and 50 characters" |
| Savings % | 5-50% | "Savings rate must be between 5% and 50%" |
| Emergency Multiplier | 1-12 | "Multiplier must be between 1 and 12" |

---

## Out of Scope (MVP)

| Feature | Reason | Phase |
|---------|--------|-------|
| Appearance/theme | System default sufficient | Phase 2 |
| Notifications | Requires notification system | Phase 2 |
| iCloud sync | Complexity | Phase 2+ |
| Data import | Export first | Phase 2 |
| Biometric lock | Security feature | Phase 2 |
| Widgets configuration | No widgets MVP | Phase 2 |

---

## Open Questions

1. **Settings persistence:** SwiftData vs UserDefaults?
   - **Recommendation:** UserDefaults for simple values; SwiftData for complex.

2. **Currency change impact:** Should changing currency convert values?
   - **Recommendation:** No conversion MVP; display format only. Warn user.

3. **Reset granularity:** Reset all vs reset specific data?
   - **Recommendation:** Reset all for MVP; granular reset Phase 2.

---

## References

- [01-Onboarding.md](./01-Onboarding.md) - Initial settings setup
- [07-Savings.md](./07-Savings.md) - Savings percentage details
- [05-EmergencyFund.md](./05-EmergencyFund.md) - Emergency fund multiplier
- [08-Accounts.md](./08-Accounts.md) - Account management
- [04-Categories.md](./04-Categories.md) - Category management
