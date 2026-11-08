import SwiftUI
import SwiftData
import os
import DesignSystem
import Persistence
import Utilities

/// State is seeded once in `init`, so a store refresh (e.g. after saving an account) never
/// discards unsaved edits.
struct SettingsForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let accounts: [Account]
    let monthlyIncome: Decimal
    let availableIncome: Decimal

    @State private var name: String
    @State private var currency: Currency
    @State private var remainingDestination: RemainingMoneyDestination
    @State private var allocation: SavingsAllocationEntry

    @State private var editingAccount: Account?
    @State private var saveFailed = false

    init(
        name: String,
        currency: Currency,
        remainingDestination: RemainingMoneyDestination,
        allocation: SavingsAllocationEntry,
        accounts: [Account],
        monthlyIncome: Decimal,
        availableIncome: Decimal
    ) {
        let accountEntries = accounts.map { $0.toEntry() }
        _name = State(initialValue: name)
        _currency = State(initialValue: currency)
        _remainingDestination = State(initialValue: accountEntries.resolvedRemainingDestination(remainingDestination))
        _allocation = State(initialValue: allocation)
        self.accounts = accounts
        self.monthlyIncome = monthlyIncome
        self.availableIncome = availableIncome
    }

    private var accountEntries: [AccountEntry] {
        accounts.map { $0.toEntry() }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Name".localized) {
                        TextField("Name".localized, text: $name, prompt: Text("Your name".localized))
                            .multilineTextAlignment(.trailing)
                            .textContentType(.givenName)
                    }

                    Picker("Currency".localized, selection: $currency) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text(currency.displayName).tag(currency)
                        }
                    }
                } header: {
                    Text("Profile".localized)
                }

                SettingsSavingsSection(
                    allocation: $allocation,
                    availableIncome: availableIncome,
                    currencyCode: currency.rawValue,
                    hasEmergencyAccount: accounts.contains { $0.accountType == .emergency },
                    hasSavingsAccount: accounts.contains { $0.accountType == .savings || $0.isPrimarySavings }
                )

                Section {
                    ForEach(accounts) { account in
                        Button {
                            editingAccount = account
                        } label: {
                            SettingsAccountRow(account: account.toEntry(), currencyCode: currency.rawValue)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Accounts".localized)
                } footer: {
                    Text("Tap an account to edit its settings.".localized)
                }

                Section {
                    Picker("Destination".localized, selection: $remainingDestination) {
                        ForEach(accountEntries.availableRemainingDestinations, id: \.self) { destination in
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
            .scrollIndicators(.hidden)
            .navigationTitle("Settings".localized)
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
                        .disabled(trimmedName.isEmpty)
                }
            }
            .sheet(item: $editingAccount) { account in
                AccountEditorSheet(
                    account: account.toEntry(),
                    allAccounts: accountEntries,
                    monthlyIncome: monthlyIncome,
                    currencyCode: currency.rawValue
                )
            }
            .saveFailedAlert(isPresented: $saveFailed)
        }
    }

    private func save() {
        do {
            try modelContext.saveSettings(
                name: trimmedName,
                currencyCode: currency.rawValue,
                remainingMoneyDestination: remainingDestination,
                savingsAllocation: allocation
            )
            dismiss()
        } catch {
            Logger.persistence.error("Saving settings failed: \(error)")
            saveFailed = true
        }
    }
}

private extension RemainingMoneyDestination {
    var displayName: String {
        switch self {
        case .primarySavings: return "Primary Savings".localized
        case .personal: return "Personal Account".localized
        case .primary: return "Primary Account".localized
        }
    }
}
