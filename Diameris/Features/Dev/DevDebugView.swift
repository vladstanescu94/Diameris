#if DEBUG
import SwiftUI
import SwiftData
import Onboarding

struct DevDebugView: View {
    @AppStorage(AppStorageKeys.onboardingCompleted) private var onboardingCompleted = false
    @Environment(\.modelContext) private var modelContext

    @State private var showingResetConfirmation = false

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
        }
    }

    private func clearAllData() {
        do {
            try modelContext.delete(model: UserProfile.self)
            try modelContext.delete(model: Income.self)
            try modelContext.delete(model: Expense.self)
            try modelContext.delete(model: Account.self)
            try modelContext.save()
        } catch {
            print("Failed to clear data: \(error)")
        }

        onboardingCompleted = false
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
        .modelContainer(for: [UserProfile.self, Income.self, Expense.self, Account.self], inMemory: true)
}
#endif
