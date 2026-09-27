import Foundation
import SwiftData
import Observation

/// Calls `onDataChanged` after every `ModelContext` save, from any context.
@Observable
@MainActor
final class DataObserver {
    // MARK: - Callbacks

    var onDataChanged: (() -> Void)?

    // MARK: - Private State

    private var notificationTask: Task<Void, Never>?

    // MARK: - Init

    init() {}

    // MARK: - Lifecycle

    func startObserving(modelContext: ModelContext) {
        stopObserving()

        notificationTask = Task { @MainActor [weak self] in
            let notifications = NotificationCenter.default.notifications(
                named: ModelContext.didSave
            )

            for await _ in notifications {
                guard !Task.isCancelled else { break }
                self?.onDataChanged?()
            }
        }
    }

    func stopObserving() {
        notificationTask?.cancel()
        notificationTask = nil
    }
}
