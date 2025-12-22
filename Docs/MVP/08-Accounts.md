# Accounts

## Overview

Accounts represent the user's bank accounts or money containers where income arrives and funds are allocated. Diameris uses accounts to generate transfer suggestions after payday. Each user has one **primary account** (where income lands) and optional **additional accounts** for savings, emergency fund, joint expenses, etc.

**Key Principle:** Accounts are containers for allocation planning, not real-time balance trackers. MVP calculates suggested transfers, not actual balances.

---

## User Stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| User | Define my primary account | The app knows where my income arrives |
| User | Add additional accounts | I can plan transfers to savings, emergency, etc. |
| User | Describe each account's purpose | I remember what each is for |
| User | Reorder my accounts | They appear in my preferred order |
| User | Edit account names | I can customize my setup |

---

## Account Model

### Core Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID | Yes | Unique identifier |
| `name` | String | Yes | Account name (e.g., "Main Checking") |
| `purpose` | String? | No | Description of what this account is for |
| `isPrimary` | Bool | Yes | Whether this is the primary income account |
| `accountType` | AccountType | Yes | Type categorization |
| `sortOrder` | Int | Yes | Display order |
| `createdAt` | Date | Yes | When added |

### Account Types

```swift
enum AccountType: String, Codable, CaseIterable {
    case checking      // Primary, day-to-day account
    case savings       // Regular savings
    case emergency     // Emergency fund
    case joint         // Shared account (partner/family)
    case other         // User-defined

    var icon: String {
        switch self {
        case .checking: return "building.columns"
        case .savings: return "banknote"
        case .emergency: return "shield.checkered"
        case .joint: return "person.2"
        case .other: return "folder"
        }
    }

    var defaultName: String {
        switch self {
        case .checking: return String(localized: "Main Checking")
        case .savings: return String(localized: "Savings")
        case .emergency: return String(localized: "Emergency Fund")
        case .joint: return String(localized: "Joint Account")
        case .other: return String(localized: "Other")
        }
    }
}
```

### Domain Entity

```swift
// Domain/Entities/Account.swift
struct Account: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var purpose: String?
    var isPrimary: Bool
    var accountType: AccountType
    var sortOrder: Int
    var createdAt: Date

    // Convenience for display
    var displayName: String {
        name.isEmpty ? accountType.defaultName : name
    }
}
```

---

## Example Account Setup (from Python Script)

The Python script uses these ING subaccounts:

| Name | Type | Purpose |
|------|------|---------|
| Main | checking | Salary arrives here, automatic payments |
| Joint | joint | Shared food expenses with partner |
| Emergency | emergency | 3x salary safety net |
| Savings | savings | Regular savings |
| Personal | other | Flexible spending money |

---

## UI/UX

### Accounts List (Settings or Onboarding)

```
┌─────────────────────────────────────┐
│  ← Accounts                    [+]  │
│                                     │
│  PRIMARY ACCOUNT                    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🏦 Main Checking        ★   │    │
│  │    Salary & automatic       │    │
│  │    payments                 │    │
│  └─────────────────────────────┘    │
│                                     │
│  ADDITIONAL ACCOUNTS                │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 👥 Joint Account            │    │
│  │    Shared food expenses     │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🛡️ Emergency Fund           │    │
│  │    3x salary safety net     │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 💰 Savings                  │    │
│  │    Regular savings          │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🎯 Personal                 │    │
│  │    Flexible spending        │    │
│  └─────────────────────────────┘    │
│                                     │
│  Drag to reorder                    │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Primary account marked with star
- Account type icon
- Purpose displayed as subtitle
- Drag to reorder
- Tap to edit
- Swipe to delete (non-primary only)

### Add/Edit Account Sheet

```
┌─────────────────────────────────────┐
│  Add Account                    ✕   │
│                                     │
│  Account Type                       │
│  ┌─────────────────────────────┐    │
│  │ ○ 🏦 Checking               │    │
│  │ ○ 💰 Savings                │    │
│  │ ● 🛡️ Emergency              │    │
│  │ ○ 👥 Joint                  │    │
│  │ ○ 📁 Other                  │    │
│  └─────────────────────────────┘    │
│                                     │
│  Name                               │
│  ┌─────────────────────────────┐    │
│  │  Emergency Fund             │    │
│  └─────────────────────────────┘    │
│                                     │
│  Purpose (optional)                 │
│  ┌─────────────────────────────┐    │
│  │  3x salary safety net       │    │
│  └─────────────────────────────┘    │
│                                     │
│           [Save Account]            │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Type selection with icons
- Name auto-fills based on type selection
- Purpose is optional but encouraged

### Quick Add Suggestions

During onboarding or when adding accounts, offer quick-add suggestions:

```
┌─────────────────────────────────────┐
│  Add Account                        │
│                                     │
│  QUICK ADD                          │
│                                     │
│  [+ Emergency Fund]                 │
│  [+ Savings]                        │
│  [+ Joint Account]                  │
│                                     │
│  Or create custom...                │
│                                     │
└─────────────────────────────────────┘
```

---

## Account Rules

### Primary Account
- Exactly one account must be primary
- Cannot delete the primary account
- Can change primary by setting another account as primary
- Primary account is where income is assumed to arrive

### Additional Accounts
- Unlimited additional accounts allowed
- Can be deleted at any time
- Can be reordered
- Used in transfer planning

---

## Transfer Destinations

Accounts are linked to transfer planning. Each account can be a destination for specific allocations:

```swift
struct AccountAllocation {
    let account: Account
    let amount: Decimal
    let purpose: AllocationPurpose
}

enum AllocationPurpose {
    case expenses         // Stay in primary for automatic payments
    case emergencyFund    // To emergency account
    case regularSavings   // To savings account
    case shared           // To joint account (e.g., food)
    case flexible         // To personal spending account
}
```

See [09-TransferPlanning.md](./09-TransferPlanning.md) for full allocation logic.

---

## Implementation Notes

### SwiftData Entity

```swift
// Platform/Persistence/AccountEntity.swift
@Model
final class AccountEntity {
    var id: UUID
    var name: String
    var purpose: String?
    var isPrimary: Bool
    var accountType: String  // Raw value of AccountType
    var sortOrder: Int
    var createdAt: Date

    func toDomain() -> Account {
        Account(
            id: id,
            name: name,
            purpose: purpose,
            isPrimary: isPrimary,
            accountType: AccountType(rawValue: accountType) ?? .other,
            sortOrder: sortOrder,
            createdAt: createdAt
        )
    }
}
```

### Repository Protocol

```swift
protocol AccountRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [Account]
    func fetchPrimary() async throws -> Account?
    func fetchByType(_ type: AccountType) async throws -> [Account]
    func save(_ account: Account) async throws
    func delete(_ account: Account) async throws
    func reorder(_ accounts: [Account]) async throws
    func setPrimary(_ account: Account) async throws
}
```

### Default Setup

On first launch (after onboarding):
- Create primary checking account (from onboarding)
- Optionally create additional accounts (from onboarding)
- If no accounts from onboarding, create default primary

```swift
func ensurePrimaryAccountExists() async throws {
    let primary = try await fetchPrimary()
    if primary == nil {
        let defaultPrimary = Account(
            id: UUID(),
            name: String(localized: "Main Account"),
            purpose: String(localized: "Primary income and expenses"),
            isPrimary: true,
            accountType: .checking,
            sortOrder: 0,
            createdAt: Date()
        )
        try await save(defaultPrimary)
    }
}
```

---

## Validation Rules

| Rule | Validation | Error Message |
|------|------------|---------------|
| Name required | `name.count >= 1` | "Please enter an account name" |
| Name length | `name.count <= 50` | "Account name is too long" |
| One primary | Exactly one `isPrimary = true` | "One account must be primary" |
| Purpose length | `purpose?.count ?? 0 <= 200` | "Purpose description is too long" |

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Delete last non-primary | Allow |
| Delete primary | Prevent; show error |
| Change primary | Set new primary, unset old |
| No accounts | Auto-create default primary |
| Duplicate names | Allow; warn user |

---

## Out of Scope (MVP)

| Feature | Reason | Phase |
|---------|--------|-------|
| Actual balance tracking | Complexity; suggested allocations only | Phase 2 |
| Bank integration | 3rd party APIs | Phase 2+ |
| Account icons customization | Default icons sufficient | Phase 2 |
| Account color coding | Nice-to-have | Phase 2 |
| Multi-currency accounts | Single currency MVP | Phase 2 |

---

## Open Questions

1. **Account limit:** Should there be a maximum number of accounts?
   - **Recommendation:** No hard limit; reasonable UX for 5-10 accounts.

2. **Account merging:** What happens to allocations if accounts are deleted?
   - **Recommendation:** Warn user; reallocate to primary or let user choose.

3. **Bank name field:** Should accounts have an optional bank name?
   - **Recommendation:** Phase 2; purpose field can include bank info.

---

## References

- [01-Onboarding.md](./01-Onboarding.md) - Account setup during onboarding
- [09-TransferPlanning.md](./09-TransferPlanning.md) - Account allocations
- Python script ING subaccount structure in `planifica_transferuri_ing()`
