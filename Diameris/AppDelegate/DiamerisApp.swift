//
//  DiamerisApp.swift
//  Diameris
//
//  Created by Vlad Stanescu on 22.12.2025.
//

import SwiftUI
import SwiftData
import Onboarding
import Dashboard
import DesignSystem

@main
struct DiamerisApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Income.self,
            Expense.self,
            Account.self,
            SavingsAllocation.self,
            MonthlyRecord.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

private struct RootView: View {
    @AppStorage(AppStorageKeys.onboardingCompleted) private var onboardingCompleted = false
    @State private var showMainTab = false

    var body: some View {
        ZStack {
            if showMainTab {
                MainTabView()
                    .transition(.opacity)
            }

            if !onboardingCompleted {
                OnboardingContainerView {
                    completeOnboarding()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: AnimationDuration.medium), value: onboardingCompleted)
        .animation(.easeInOut(duration: AnimationDuration.medium), value: showMainTab)
        .onAppear {
            // If already completed, show main tab immediately
            if onboardingCompleted {
                showMainTab = true
            }
        }
        .onChange(of: onboardingCompleted) { _, newValue in
            // Sync showMainTab when onboarding is reset
            if !newValue {
                showMainTab = false
            }
        }
    }

    private func completeOnboarding() {
        // Dismiss keyboard first
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

        // Small delay to let keyboard dismiss, then transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showMainTab = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                onboardingCompleted = true
            }
        }
    }
}
