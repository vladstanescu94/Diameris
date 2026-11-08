import SwiftUI
import SwiftData
import os
import DesignSystem
import Persistence
import Utilities

struct AccountEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let original: AccountEntry
    private let allAccounts: [AccountEntry]
    let monthlyIncome: Decimal
    let currencyCode: String

    @State private var name: String
    @State private var accountType: AccountType
    @State private var isPrimarySavings: Bool
    @State private var emergencyMultiplier: Double
    @State private var hardCapEnabled: Bool
    @State private var hardCap: Decimal
    @State private var currentBalance: Decimal
    @State private var saveFailed = false

    private static let emergencyMultipliers: [Double] = [3, 4, 5, 6]

    init(account: AccountEntry, allAccounts: [AccountEntry], monthlyIncome: Decimal, currencyCode: String) {
        original = account
        self.allAccounts = allAccounts
        self.monthlyIncome = monthlyIncome
        self.currencyCode = currencyCode
        _name = State(initialValue: account.name)
        _accountType = State(initialValue: account.accountType)
        _isPrimarySavings = State(initialValue: account.isPrimarySavings)
        _emergencyMultiplier = State(initialValue: account.emergencyMultiplier ?? Self.emergencyMultipliers[0])
        _hardCapEnabled = State(initialValue: account.emergencyHardCap != nil)
        _hardCap = State(initialValue: account.emergencyHardCap ?? 0)
        _currentBalance = State(initialValue: account.currentBalance)
    }

    private var assignableTypes: [AccountType] {
        AccountType.allCases.filter { allAccounts.canAssign($0, toAccount: original.id) }
    }

    /// Role fields only apply to the matching account type.
    private var editedAccount: AccountEntry {
        var account = original
        account.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        account.accountType = accountType
        account.isPrimarySavings = accountType == .savings && isPrimarySavings
        account.emergencyMultiplier = accountType == .emergency ? emergencyMultiplier : nil
        account.emergencyHardCap = accountType == .emergency && hardCapEnabled && hardCap > 0 ? hardCap : nil
        account.currentBalance = currentBalance
        return account
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Account Name".localized, text: $name)
                }

                if !original.isPrimary {
                    Section {
                        Picker("Type".localized, selection: $accountType) {
                            ForEach(assignableTypes, id: \.self) { type in
                                Label(type.displayName, systemImage: type.icon)
                                    .tag(type)
                            }
                        }
                    } header: {
                        Text("Account Type".localized)
                    }
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
                    AmountField("Current Balance".localized, amount: $currentBalance, currencyCode: currencyCode)
                } header: {
                    Text("Balance".localized)
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Edit Account".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save".localized, action: save)
                        .bold()
                        .disabled(editedAccount.name.isEmpty)
                }
            }
            .saveFailedAlert(isPresented: $saveFailed)
        }
    }

    private func save() {
        do {
            try modelContext.updateAccount(editedAccount)
            dismiss()
        } catch {
            Logger.persistence.error("Saving account failed: \(error)")
            saveFailed = true
        }
    }

    // MARK: - Emergency Target

    private var emergencyTargetSection: some View {
        Section {
            Picker("Target".localized, selection: $emergencyMultiplier) {
                ForEach(Self.emergencyMultipliers, id: \.self) { multiplier in
                    Text(verbatim: "\(multiplier.formatted())× \("monthly income".localized)")
                        .tag(multiplier)
                }
            }

            if monthlyIncome > 0 {
                targetAmountRow
            }

            Toggle("Set maximum amount".localized, isOn: $hardCapEnabled)
                .tint(DiamerisColors.warning)
                .accessibilityHint("Caps the emergency fund target at a fixed amount".localized)

            if hardCapEnabled {
                AmountField("Maximum".localized, amount: $hardCap, currencyCode: currencyCode)
            }
        } header: {
            Text("Emergency Fund Target".localized)
        } footer: {
            if hardCapEnabled {
                Text("The fund target will be capped at this amount regardless of income multiplier.".localized)
            }
        }
    }

    private var emergencyTarget: Decimal {
        editedAccount.emergencyTarget(monthlyIncome: monthlyIncome) ?? 0
    }

    private var uncappedEmergencyTarget: Decimal {
        editedAccount.uncappedEmergencyTarget(monthlyIncome: monthlyIncome) ?? 0
    }

    private var targetAmountRow: some View {
        let target = emergencyTarget
        let uncappedTarget = uncappedEmergencyTarget

        return LabeledContent("Target Amount".localized) {
            HStack(spacing: Spacing.xs) {
                if target < uncappedTarget {
                    Text(AmountFormatter.formatForDisplay(uncappedTarget, currency: currencyCode))
                        .strikethrough()
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                Text(AmountFormatter.formatForDisplay(target, currency: currencyCode))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
