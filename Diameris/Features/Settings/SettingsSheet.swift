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
    @Query private var expenses: [Expense]

    // MARK: - Editable State

    @State private var userName: String = ""
    @State private var selectedCurrency: Currency = .ron
    @State private var savingsPercentage: Double = 0.25
    @State private var boostEnabled: Bool = false
    @State private var boostMultiplier: Double = 3.0
    @State private var remainingDestination: RemainingMoneyDestination = .primarySavings
    @State private var allocationMode: AllocationMode = .prioritized
    @State private var savingsInputMode: SavingsInputMode = .percentage
    @State private var savingsFixedAmount: Decimal = 0
    @State private var savingsFixedAmountText: String = ""
    @State private var splitEmergencyInputMode: SavingsInputMode = .fixedAmount
    @State private var splitEmergencyPercentage: Double = 0.10
    @State private var splitEmergencyAmount: Decimal = 0
    @State private var splitEmergencyAmountText: String = ""
    @State private var splitSavingsInputMode: SavingsInputMode = .fixedAmount
    @State private var splitSavingsPercentage: Double = 0.15
    @State private var splitSavingsAmount: Decimal = 0
    @State private var splitSavingsAmountText: String = ""

    // MARK: - UI State

    @State private var showingAccountEditor: Bool = false
    @State private var selectedAccount: Account?

    private var userProfile: UserProfile? { userProfiles.first }
    private var savingsAllocation: SavingsAllocation? { savingsAllocations.first }
    private var monthlyIncome: Decimal { incomes.first?.amount ?? 0 }

    private var totalExpenses: Decimal {
        expenses.filter { $0.isEnabled }.reduce(0) { $0 + $1.monthlyAmount }
    }

    private var availableIncome: Decimal {
        max(0, monthlyIncome - totalExpenses)
    }

    private var hasEmergencyAccount: Bool {
        accounts.contains { $0.accountType == .emergency }
    }

    private var hasSavingsAccount: Bool {
        accounts.contains { $0.accountType == .savings || $0.isPrimarySavings }
    }

    private var resolvedSplitTotal: Decimal {
        let entry = SavingsAllocationEntry(
            allocationMode: .split,
            splitEmergencyInputMode: splitEmergencyInputMode,
            splitEmergencyAmount: splitEmergencyAmount,
            splitEmergencyPercentage: splitEmergencyPercentage,
            splitSavingsInputMode: splitSavingsInputMode,
            splitSavingsAmount: splitSavingsAmount,
            splitSavingsPercentage: splitSavingsPercentage
        )
        return entry.splitTotal(availableIncome: availableIncome)
    }

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
                    .bold()
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
            allocationModePicker

            if allocationMode == .prioritized {
                prioritizedModeContent
            } else {
                splitModeContent
            }
        } header: {
            Text("Savings".localized)
        } footer: {
            Text(savingsSectionFooter)
        }
    }

    var allocationModePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Picker("Allocation Mode".localized, selection: $allocationMode) {
                ForEach(AllocationMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(allocationMode.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    var prioritizedModeContent: some View {
        Picker("Savings Type".localized, selection: $savingsInputMode) {
            ForEach(SavingsInputMode.allCases) { mode in
                Text(mode.displayName).tag(mode)
            }
        }
        .pickerStyle(.segmented)

        if savingsInputMode == .percentage {
            percentageModeContent
        } else {
            fixedAmountModeContent
        }
    }

    var percentageModeContent: some View {
        Group {
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
                    Picker("Boost Multiplier".localized, selection: $boostMultiplier) {
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
        }
    }

    var fixedAmountModeContent: some View {
        HStack {
            Text("Monthly Savings".localized)
            Spacer()
            TextField("0", text: $savingsFixedAmountText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: ComponentSize.balanceInputWidth)
                .onChange(of: savingsFixedAmountText) { _, newValue in
                    savingsFixedAmount = AmountFormatter.parse(newValue)
                }
            Text(selectedCurrency.rawValue)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    var splitModeContent: some View {
        if hasEmergencyAccount {
            Label("Emergency".localized, systemImage: AccountType.emergency.icon)
                .font(.subheadline)

            Picker("Emergency".localized, selection: $splitEmergencyInputMode) {
                ForEach(SavingsInputMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if splitEmergencyInputMode == .percentage {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("Rate".localized)
                        Spacer()
                        Text("\(Int(splitEmergencyPercentage * 100))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $splitEmergencyPercentage, in: 0.05...0.50, step: 0.01)
                        .tint(DiamerisColors.accentSecondary)
                }
            } else {
                HStack {
                    Spacer()
                    TextField("0", text: $splitEmergencyAmountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: ComponentSize.balanceInputWidth)
                        .onChange(of: splitEmergencyAmountText) { _, newValue in
                            splitEmergencyAmount = AmountFormatter.parse(newValue)
                        }
                    Text(selectedCurrency.rawValue)
                        .foregroundStyle(.secondary)
                }
            }
        }

        if hasSavingsAccount {
            Label("Savings".localized, systemImage: AccountType.savings.icon)
                .font(.subheadline)

            Picker("Savings".localized, selection: $splitSavingsInputMode) {
                ForEach(SavingsInputMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if splitSavingsInputMode == .percentage {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("Rate".localized)
                        Spacer()
                        Text("\(Int(splitSavingsPercentage * 100))%")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $splitSavingsPercentage, in: 0.05...0.50, step: 0.01)
                        .tint(DiamerisColors.accentSecondary)
                }
            } else {
                HStack {
                    Spacer()
                    TextField("0", text: $splitSavingsAmountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: ComponentSize.balanceInputWidth)
                        .onChange(of: splitSavingsAmountText) { _, newValue in
                            splitSavingsAmount = AmountFormatter.parse(newValue)
                        }
                    Text(selectedCurrency.rawValue)
                        .foregroundStyle(.secondary)
                }
            }
        }

        if hasEmergencyAccount || hasSavingsAccount {
            splitTotalRow
        }
    }

    var splitTotalRow: some View {
        HStack {
            Text("Total Monthly".localized)
                .bold()
            Spacer()
            Text(AmountFormatter.formatForDisplay(resolvedSplitTotal, currency: selectedCurrency.rawValue))
                .bold()
                .foregroundStyle(resolvedSplitTotal > availableIncome ? .red : DiamerisColors.accentPrimary)
                .monospacedDigit()
        }
    }

    var savingsSectionFooter: String {
        if allocationMode == .split && resolvedSplitTotal > availableIncome && availableIncome > 0 {
            return "Total exceeds available income. Amounts will be reduced proportionally.".localized
        }
        return "Savings are calculated from income after expenses.".localized
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
                        emergencyMultiplierBadge(multiplier: multiplier, hardCap: account.emergencyHardCap)
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

// MARK: - Helper Views

private extension SettingsSheet {
    func emergencyMultiplierBadge(multiplier: Double, hardCap: Decimal?) -> some View {
        let badgeText = emergencyBadgeText(multiplier: multiplier, hardCap: hardCap)
        return Text(badgeText)
            .font(.caption)
            .foregroundStyle(DiamerisColors.accentSecondary)
    }

    func emergencyBadgeText(multiplier: Double, hardCap: Decimal?) -> String {
        let currencyCode = userProfile?.currencyCode ?? "RON"
        let multiplierInt = Int(multiplier)
        let incomeText = "income".localized

        if let cap = hardCap {
            let capFormatted = AmountFormatter.formatForDisplay(cap, currency: currencyCode)
            let maxText = "max".localized
            return "• \(multiplierInt)× \(incomeText) (\(maxText) \(capFormatted))"
        } else {
            return "• \(multiplierInt)× \(incomeText)"
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
            allocationMode = allocation.allocationMode
            savingsInputMode = allocation.savingsInputMode
            savingsFixedAmount = allocation.fixedAmount
            savingsFixedAmountText = allocation.fixedAmount > 0
                ? AmountFormatter.formatForEditing(allocation.fixedAmount) : ""
            splitEmergencyInputMode = allocation.splitEmergencyInputMode
            splitEmergencyPercentage = allocation.splitEmergencyPercentage
            splitEmergencyAmount = allocation.splitEmergencyAmount
            splitEmergencyAmountText = allocation.splitEmergencyAmount > 0
                ? AmountFormatter.formatForEditing(allocation.splitEmergencyAmount) : ""
            splitSavingsInputMode = allocation.splitSavingsInputMode
            splitSavingsPercentage = allocation.splitSavingsPercentage
            splitSavingsAmount = allocation.splitSavingsAmount
            splitSavingsAmountText = allocation.splitSavingsAmount > 0
                ? AmountFormatter.formatForEditing(allocation.splitSavingsAmount) : ""
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
            allocation.allocationMode = allocationMode
            allocation.savingsInputMode = savingsInputMode
            allocation.fixedAmount = savingsFixedAmount
            allocation.splitEmergencyInputMode = splitEmergencyInputMode
            allocation.splitEmergencyPercentage = splitEmergencyPercentage
            allocation.splitEmergencyAmount = splitEmergencyAmount
            allocation.splitSavingsInputMode = splitSavingsInputMode
            allocation.splitSavingsPercentage = splitSavingsPercentage
            allocation.splitSavingsAmount = splitSavingsAmount
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
    @State private var emergencyHardCapEnabled: Bool = false
    @State private var emergencyHardCap: Decimal = 0
    @State private var emergencyHardCapText: String = ""
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
                    emergencyTargetSection
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
                    .bold()
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
        emergencyHardCapEnabled = account.emergencyHardCap != nil
        emergencyHardCap = account.emergencyHardCap ?? 0
        if let cap = account.emergencyHardCap {
            emergencyHardCapText = AmountFormatter.formatForEditing(cap)
        }
        currentBalance = account.currentBalance
    }

    private func saveAccount() {
        account.name = name
        account.accountType = accountType
        account.isPrimarySavings = accountType == .savings ? isPrimarySavings : false
        account.emergencyMultiplier = accountType == .emergency ? emergencyMultiplier : nil
        account.emergencyHardCap = accountType == .emergency && emergencyHardCapEnabled && emergencyHardCap > 0
            ? emergencyHardCap
            : nil
        account.currentBalance = currentBalance

        try? modelContext.save()
    }

    // MARK: - Emergency Target Section

    private var calculatedTarget: Decimal {
        monthlyIncome * Decimal(emergencyMultiplier)
    }

    private var effectiveTarget: Decimal {
        if emergencyHardCapEnabled && emergencyHardCap > 0 {
            return min(calculatedTarget, emergencyHardCap)
        }
        return calculatedTarget
    }

    private var isHardCapActive: Bool {
        emergencyHardCapEnabled && emergencyHardCap > 0 && emergencyHardCap < calculatedTarget
    }

    private var emergencyTargetSection: some View {
        Section {
            Picker("Target".localized, selection: $emergencyMultiplier) {
                Text("3× " + "monthly income".localized).tag(3.0)
                Text("4× " + "monthly income".localized).tag(4.0)
                Text("5× " + "monthly income".localized).tag(5.0)
                Text("6× " + "monthly income".localized).tag(6.0)
            }

            if monthlyIncome > 0 {
                targetAmountRow
            }

            Toggle("Set maximum amount".localized, isOn: $emergencyHardCapEnabled)
                .tint(.orange)
                .accessibilityHint("Caps the emergency fund target at a fixed amount".localized)

            if emergencyHardCapEnabled {
                hardCapInputRow
            }
        } header: {
            Text("Emergency Fund Target".localized)
        } footer: {
            if emergencyHardCapEnabled {
                Text("The fund target will be capped at this amount regardless of income multiplier.".localized)
            }
        }
    }

    private var targetAmountRow: some View {
        HStack {
            Text("Target Amount".localized)
            Spacer()
            if isHardCapActive {
                HStack(spacing: Spacing.xs) {
                    Text(AmountFormatter.formatForDisplay(calculatedTarget, currency: currency.rawValue))
                        .strikethrough()
                        .foregroundStyle(.tertiary)
                    Text(AmountFormatter.formatForDisplay(effectiveTarget, currency: currency.rawValue))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(AmountFormatter.formatForDisplay(effectiveTarget, currency: currency.rawValue))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var hardCapInputRow: some View {
        HStack {
            Text("Maximum".localized)
            Spacer()
            TextField("0", text: $emergencyHardCapText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: ComponentSize.mediumInputWidth)
                .onChange(of: emergencyHardCapText) { _, newValue in
                    emergencyHardCap = AmountFormatter.parse(newValue)
                }
                .accessibilityLabel("Maximum amount".localized)
        }
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
