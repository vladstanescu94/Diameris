import Foundation
import SwiftData
import Testing
@testable import Persistence

@MainActor
struct OnboardingFlagRestoreTests {
    private static let key = "onboardingCompleted"

    @Test(arguments: [true, false])
    func lostFlagIsRestoredOnlyWhenAProfileIsStored(hasProfile: Bool) throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        if hasProfile {
            context.insert(UserProfile(name: "Ana", currencyCode: "EUR"))
            try context.save()
        }
        let suiteName = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let restored = try context.restoreOnboardingFlag(in: defaults, forKey: Self.key)

        #expect(restored == hasProfile)
        #expect(defaults.bool(forKey: Self.key) == hasProfile, "a new user must still see onboarding")
    }
}
