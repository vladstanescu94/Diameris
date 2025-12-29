import SwiftUI
import SwiftData
import DesignSystem
import Domain
import Utilities
import Onboarding
import SharedUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var userProfiles: [UserProfile]
    @Query private var savingsAllocations: [SavingsAllocation]
    @Query private var accounts: [Account]
    @Query private var incomes: [Income]

    // MARK: - Editable State

    @State private var userName: String = ""
    @State private var selectedCurrency: Currency = .ron
    @State private var savingsPercentage: Double = 0.25
    @State private var boostEnabled: Bool = false
    @State private var boostMultiplier: Double = 3.0
    @State private var remainingDestination: RemainingMoneyDestination = .primarySavings

    // MARK: - UI State

    @State private var showingAccountEditor: Bool = false
    @State private var selectedAccount: Account?

    private var userProfile: UserProfile? { userProfiles.first }
    private var savingsAllocation: SavingsAllocation? { savingsAllocations.first }
    private var monthlyIncome: Decimal { incomes.first?.amount ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                savingsSection
                accountsSection
                remainingMoneySection
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Settings".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadCurrentValues()
            }
            .sheet(item: $selectedAccount) { account in
                AccountEditorSheet(account: account, currency: selectedCurrency)
            }
        }
    }
}

// MARK: - Sections

private extension SettingsSheet {
    var profileSection: some View {
        Section {
            HStack {
                Text("Name".localized)
                Spacer()
                TextField("Your name".localized, text: $userName)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }

            Picker("Currency".localized, selection: $selectedCurrency) {
                ForEach(Currency.allCases, id: \.self) { currency in
                    Text(currency.displayName).tag(currency)
                }
            }
        } header: {
            Text("Profile".localized)
        }
    }

    var savingsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Savings Rate".localized)
                    Spacer()
                    Text("\(Int(savingsPercentage * 100))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Slider(value: $savingsPercentage, in: 0.05...0.50, step: 0.01)
                    .tint(DiamerisColors.accentPrimary)
            }

            Toggle("Savings Boost".localized, isOn: $boostEnabled)
                .tint(DiamerisColors.accentPrimary)

            if boostEnabled {
                HStack {
                    Text("Boost Multiplier".localized)
                    Spacer()
                    Picker("", selection: $boostMultiplier) {
                        Text("2×").tag(2.0)
                        Text("3×").tag(3.0)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: ComponentSize.segmentedControlCompact)
                }
            }

            if boostEnabled {
                HStack {
                    Text("Effective Rate".localized)
                    Spacer()
                    Text("\(Int(min(100, savingsPercentage * boostMultiplier * 100)))%")
                        .foregroundStyle(DiamerisColors.accentPrimary)
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
            }
        } header: {
            Text("Savings".localized)
        } footer: {
            Text("Savings are calculated from income after expenses.".localized)
        }
    }

    var accountsSection: some View {
        Section {
            ForEach(accounts.sorted(by: { $0.sortOrder < $1.sortOrder })) { account in
                Button {
                    selectedAccount = account
                } label: {
                    accountRow(for: account)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Accounts".localized)
        } footer: {
            Text("Tap an account to edit its settings.".localized)
        }
    }

    func accountRow(for account: Account) -> some View {
        HStack {
            Image(systemName: account.accountType.icon)
                .foregroundStyle(account.accountType.color)
                .frame(width: ComponentSize.iconContainer)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(account.name)
                    .foregroundStyle(.primary)

                HStack(spacing: Spacing.xs) {
                    Text(account.accountType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if account.isPrimarySavings {
                        Text("• " + "Primary".localized)
                            .font(.caption)
                            .foregroundStyle(DiamerisColors.accentPrimary)
                    }

                    if let multiplier = account.emergencyMultiplier {
                        Text("• \(Int(multiplier))× " + "income".localized)
                            .font(.caption)
                            .foregroundStyle(DiamerisColors.accentSecondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    var remainingMoneySection: some View {
        Section {
            Picker("Destination".localized, selection: $remainingDestination) {
                ForEach(RemainingMoneyDestination.allCases, id: \.self) { destination in
                    Text(destination.displayName).tag(destination)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("Remaining Money".localized)
        } footer: {
            Text("Where leftover money goes after savings allocation.".localized)
        }
    }
}

// MARK: - Data Loading & Saving

private extension SettingsSheet {
    func loadCurrentValues() {
        if let profile = userProfile {
            userName = profile.name
            selectedCurrency = Currency(rawValue: profile.currencyCode) ?? .ron
            remainingDestination = profile.remainingMoneyDestination
        }

        if let allocation = savingsAllocation {
            savingsPercentage = allocation.percentage
            boostEnabled = allocation.boostEnabled
            boostMultiplier = allocation.boostMultiplier
        }
    }

    func saveChanges() {
        // Update UserProfile
        if let profile = userProfile {
            profile.name = userName
            profile.currencyCode = selectedCurrency.rawValue
            profile.remainingMoneyDestination = remainingDestination
        }

        // Update SavingsAllocation
        if let allocation = savingsAllocation {
            allocation.percentage = savingsPercentage
            allocation.boostEnabled = boostEnabled
            allocation.boostMultiplier = boostMultiplier
        }

        // Save context
        try? modelContext.save()
    }
}

// MARK: - Account Editor Sheet

private struct AccountEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var account: Account
    let currency: Currency

    @Query private var incomes: [Income]
    private var monthlyIncome: Decimal { incomes.first?.amount ?? 0 }

    @State private var name: String = ""
    @State private var accountType: AccountType = .other
    @State private var isPrimarySavings: Bool = false
    @State private var emergencyMultiplier: Double = 3.0
    @State private var currentBalance: Decimal = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Account Name".localized, text: $name)
                }

                Section {
                    Picker("Type".localized, selection: $accountType) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                } header: {
                    Text("Account Type".localized)
                }

                if accountType == .savings {
                    Section {
                        Toggle("Primary Savings Account".localized, isOn: $isPrimarySavings)
                            .tint(DiamerisColors.accentPrimary)
                    } footer: {
                        Text("The primary savings account receives automatic savings allocation.".localized)
                    }
                }

                if accountType == .emergency {
                    Section {
                        Picker("Target".localized, selection: $emergencyMultiplier) {
                            Text("3× " + "monthly income".localized).tag(3.0)
                            Text("4× " + "monthly income".localized).tag(4.0)
                            Text("5× " + "monthly income".localized).tag(5.0)
                            Text("6× " + "monthly income".localized).tag(6.0)
                        }

                        if monthlyIncome > 0 {
                            HStack {
                                Text("Target Amount".localized)
                                Spacer()
                                Text(AmountFormatter.formatForDisplay(monthlyIncome * Decimal(emergencyMultiplier), currency: currency.rawValue))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Emergency Fund Target".localized)
                    }
                }

                Section {
                    HStack {
                        Text("Current Balance".localized)
                        Spacer()
                        TextField("0", value: $currentBalance, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: ComponentSize.mediumInputWidth)
                    }
                } header: {
                    Text("Balance".localized)
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Edit Account".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized) {
                        saveAccount()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadAccountValues()
            }
        }
    }

    private func loadAccountValues() {
        name = account.name
        accountType = account.accountType
        isPrimarySavings = account.isPrimarySavings
        emergencyMultiplier = account.emergencyMultiplier ?? 3.0
        currentBalance = account.currentBalance
    }

    private func saveAccount() {
        account.name = name
        account.accountType = accountType
        account.isPrimarySavings = accountType == .savings ? isPrimarySavings : false
        account.emergencyMultiplier = accountType == .emergency ? emergencyMultiplier : nil
        account.currentBalance = currentBalance

        try? modelContext.save()
    }
}

// MARK: - Helper Extensions

private extension RemainingMoneyDestination {
    var displayName: String {
        switch self {
        case .primarySavings: return "Primary Savings".localized
        case .personal: return "Personal Account".localized
        case .primary: return "Primary Account".localized
        }
    }
}

#Preview {
    SettingsSheet()
}
