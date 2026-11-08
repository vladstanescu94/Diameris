import Foundation
import os

extension Logger {
    /// SwiftData write failures. Filter in Console with `subsystem:<bundle id> category:Persistence`.
    static let persistence = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Diameris",
        category: "Persistence"
    )
}
