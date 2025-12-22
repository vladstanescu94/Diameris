//
//  DiamerisApp.swift
//  Diameris
//
//  Created by Vlad Stanescu on 22.12.2025.
//

import SwiftUI
import SwiftData
import Onboarding

@main
struct DiamerisApp: App {
    @AppStorage(AppStorageKeys.onboardingCompleted) private var onboardingCompleted = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            Income.self,
            Expense.self,
            Account.self
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
            if onboardingCompleted {
                MainTabView()
            } else {
                OnboardingContainerView {
                    onboardingCompleted = true
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
