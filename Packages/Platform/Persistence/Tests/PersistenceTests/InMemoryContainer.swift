import Foundation
import SwiftData
@testable import Persistence

/// A fresh, isolated in-memory store with the app's full schema.
func makeInMemoryContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(UUID().uuidString, isStoredInMemoryOnly: true)
    return try ModelContainer(for: Schema(PersistenceSchema.models), configurations: configuration)
}

extension ModelContext {
    func all<T: PersistentModel>(_ type: T.Type) throws -> [T] {
        try fetch(FetchDescriptor<T>())
    }
}
