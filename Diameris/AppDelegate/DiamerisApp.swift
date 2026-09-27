//
//  DiamerisApp.swift
//  Diameris
//
//  Created by Vlad Stanescu on 22.12.2025.
//

import SwiftUI
import SwiftData
import os
import Onboarding
import Persistence
import DesignSystem
import Utilities

@main
struct DiamerisApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(PersistenceSchema.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        DiamerisApp.repairStoredData(in: container.mainContext)
        DiamerisApp.restoreOnboardingFlag(in: container.mainContext)
        return container
    }()

    /// Runs at launch only, so the dev "Reset Onboarding Flag" still reaches onboarding in the
    /// same session.
    private static func restoreOnboardingFlag(in context: ModelContext) {
        do {
            if try context.restoreOnboardingFlag(in: .standard, forKey: AppStorageKeys.onboardingCompleted) {
                Logger.persistence.notice("Restored the onboarding flag from the stored profile")
            }
        } catch {
            Logger.persistence.error("Checking for a stored profile failed: \(error)")
        }
    }

    /// Runs before any view loads data. Idempotent, so it runs on every launch.
    private static func repairStoredData(in context: ModelContext) {
        do {
            switch try context.repairDanglingExpenseLinks() {
            case .nothingToRepair:
                break
            case .relinked(let expenseCount):
                Logger.persistence.notice("Relinked \(expenseCount) expenses to the Joint account")
            case .ambiguous(let expenseCount, let danglingIdCount):
                Logger.persistence.warning(
                    "\(expenseCount) expenses link to \(danglingIdCount) missing accounts; left unchanged"
                )
            }
        } catch {
            Logger.persistence.error("Repairing expense links failed: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

private struct RootView: View {
    @AppStorage(AppStorageKeys.onboardingCompleted) private var onboardingCompleted = false
    @Environment(\.modelContext) private var modelContext
    @State private var showMainTab = false
    @State private var saveFailed = false

    var body: some View {
        ZStack {
            if showMainTab {
                MainTabView()
                    .transition(.opacity)
            }

            if !onboardingCompleted {
                OnboardingContainerView { result in
                    completeOnboarding(with: result)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: AnimationDuration.medium), value: onboardingCompleted)
        .animation(.easeInOut(duration: AnimationDuration.medium), value: showMainTab)
        .onAppear {
            if onboardingCompleted {
                showMainTab = true
            }
        }
        .onChange(of: onboardingCompleted) { _, newValue in
            if !newValue {
                showMainTab = false
            }
        }
        .saveFailedAlert(isPresented: $saveFailed)
    }

    private func completeOnboarding(with result: OnboardingResult) -> Bool {
        do {
            try modelContext.saveOnboarding(result)
        } catch {
            // Stay in onboarding so the user can retry instead of landing on an empty dashboard.
            Logger.persistence.error("Saving onboarding failed: \(error)")
            HapticManager.error()
            saveFailed = true
            return false
        }

        KeyboardHelper.dismiss()

        // Let the keyboard finish dismissing before the cross-fade.
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            showMainTab = true
            try? await Task.sleep(for: .milliseconds(50))
            onboardingCompleted = true
        }
        return true
    }
}
