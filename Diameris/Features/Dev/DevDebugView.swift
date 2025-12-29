#if DEBUG
import SwiftUI
import SwiftData
import Onboarding
import Domain
import Persistence

struct DevDebugView: View {
    @AppStorage(AppStorageKeys.onboardingCompleted) private var onboardingCompleted = false
    @Environment(\.modelContext) private var modelContext

    @State private var showingResetConfirmation = false
    @State private var importResult: ImportResult?

    var body: some View {
        NavigationStack {
            List {
                Section("Onboarding") {
                    LabeledContent("Completed", value: onboardingCompleted ? "Yes" : "No")

                    Button("Reset Onboarding Flag") {
                        onboardingCompleted = false
                    }

                    Button("Clear All Data & Reset", role: .destructive) {
                        showingResetConfirmation = true
                    }
                }

                Section("Import Data") {
                    Button {
                        importFromBundle()
                    } label: {
                        Label("Import from Python Script", systemImage: "square.and.arrow.down")
                    }
                }

                Section("Data") {
                    NavigationLink("View Stored Data") {
                        DataInspectorView()
                    }
                }

                Section("App Info") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Build", value: buildNumber)
                    LabeledContent("Bundle ID", value: bundleIdentifier)
                }
            }
            .navigationTitle("Developer")
            .confirmationDialog(
                "Reset All Data?",
                isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Everything", role: .destructive) {
                    clearAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete all your data and show onboarding again. This cannot be undone.")
            }
            .alert(
                importResult?.isSuccess == true ? "Import Successful" : "Import Failed",
                isPresented: .init(
                    get: { importResult != nil },
                    set: { if !$0 { importResult = nil } }
                )
            ) {
                Button("OK") { importResult = nil }
            } message: {
                Text(importResult?.message ?? "")
            }
        }
    }

    private func clearAllData() {
        do {
            try modelContext.delete(model: UserProfile.self)
            try modelContext.delete(model: Income.self)
            try modelContext.delete(model: Expense.self)
            try modelContext.delete(model: Account.self)
            try modelContext.delete(model: SavingsAllocation.self)
            try modelContext.save()
        } catch {
            print("Failed to clear data: \(error)")
        }

        onboardingCompleted = false
    }

    private func importFromBundle() {
        guard let url = Bundle.main.url(forResource: "expenses_import", withExtension: "json") else {
            importResult = ImportResult(isSuccess: false, message: "expenses_import.json not found in bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let importData = try ExpenseImportData.parse(from: data)

            // Delete existing expenses first
            try modelContext.delete(model: Expense.self)

            // Import all expenses
            var importedExpenses = 0
            for (index, expenseData) in importData.expenses.enumerated() {
                let entry = expenseData.toExpenseEntry()
                let expense = Expense(from: entry, sortOrder: index)
                modelContext.insert(expense)
                importedExpenses += 1
            }

            // Import accounts if present
            var importedAccounts = 0
            var updatedAccounts = 0
            if let accountsData = importData.accounts {
                // Fetch existing accounts
                let existingAccounts = try modelContext.fetch(FetchDescriptor<Account>())

                for (index, accountData) in accountsData.enumerated() {
                    let accountType = accountData.accountTypeEnum

                    // Try to find existing account by type (most account types are unique)
                    if let existingAccount = existingAccounts.first(where: { $0.accountType == accountType }) {
                        // Update existing account
                        existingAccount.name = accountData.name
                        existingAccount.isPrimarySavings = accountData.isPrimarySavings
                        existingAccount.emergencyMultiplier = accountData.emergencyMultiplier
                        existingAccount.currentBalance = accountData.currentBalance
                        updatedAccounts += 1
                    } else {
                        // Create new account
                        let entry = accountData.toAccountEntry()
                        let account = Account(from: entry, sortOrder: index)
                        modelContext.insert(account)
                        importedAccounts += 1
                    }
                }
            }

            // Import savings allocation
            var savingsUpdated = false
            let existingSavings = try modelContext.fetch(FetchDescriptor<SavingsAllocation>())
            if let existingSavingsAllocation = existingSavings.first {
                // Update existing
                existingSavingsAllocation.percentage = importData.savings.percentage
                existingSavingsAllocation.boostEnabled = importData.savings.boostEnabled
                existingSavingsAllocation.boostMultiplier = Double(importData.savings.boostMultiplier)
                savingsUpdated = true
            } else {
                // Create new
                let savingsAllocation = SavingsAllocation(
                    percentage: importData.savings.percentage,
                    boostEnabled: importData.savings.boostEnabled,
                    boostMultiplier: Double(importData.savings.boostMultiplier)
                )
                modelContext.insert(savingsAllocation)
                savingsUpdated = true
            }

            try modelContext.save()

            var message = "Imported \(importedExpenses) expenses"
            if importedAccounts > 0 || updatedAccounts > 0 {
                message += ", \(importedAccounts) new accounts, \(updatedAccounts) updated"
            }
            if savingsUpdated {
                let boostStatus = importData.savings.boostEnabled ? "on" : "off"
                message += ", savings \(Int(importData.savings.percentage * 100))% (boost \(boostStatus))"
            }
            message += "!"

            importResult = ImportResult(
                isSuccess: true,
                message: message
            )
        } catch {
            importResult = ImportResult(
                isSuccess: false,
                message: "Failed to import: \(error.localizedDescription)"
            )
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }
}

// MARK: - Import Result

private struct ImportResult {
    let isSuccess: Bool
    let message: String
}

private struct DataInspectorView: View {
    @Query private var profiles: [UserProfile]
    @Query private var incomes: [Income]
    @Query private var expenses: [Expense]
    @Query private var accounts: [Account]

    var body: some View {
        List {
            Section("User Profiles (\(profiles.count))") {
                ForEach(profiles, id: \.name) { profile in
                    VStack(alignment: .leading) {
                        Text(profile.name)
                            .font(.headline)
                        Text("Currency: \(profile.currencyCode)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Incomes (\(incomes.count))") {
                ForEach(incomes, id: \.id) { income in
                    VStack(alignment: .leading) {
                        Text(income.name)
                            .font(.headline)
                        Text("\(income.amount) (\(income.frequency))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Expenses (\(expenses.count))") {
                ForEach(expenses, id: \.id) { expense in
                    HStack {
                        Image(systemName: expense.icon)
                        VStack(alignment: .leading) {
                            Text(expense.name)
                                .font(.headline)
                            Text("\(expense.amount)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Accounts (\(accounts.count))") {
                ForEach(accounts, id: \.id) { account in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(account.name)
                                .font(.headline)
                            if account.isPrimary {
                                Text("PRIMARY")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.blue.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        if let purpose = account.purpose {
                            Text(purpose)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Stored Data")
    }
}

#Preview {
    DevDebugView()
        .modelContainer(for: [UserProfile.self, Income.self, Expense.self, Account.self, SavingsAllocation.self], inMemory: true)
}
#endif
