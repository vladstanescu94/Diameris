import Foundation
import SwiftData
import Observation

/// Observes SwiftData changes and triggers refresh callbacks.
/// This provides a centralized way to react to any data changes
/// instead of scattered onChange handlers throughout the app.
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

    /// Start observing ModelContext.didSave notifications.
    /// Call this when the view appears.
    func startObserving(modelContext: ModelContext) {
        stopObserving()

        // Capture modelContext weakly for the async task
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

    /// Stop observing notifications.
    /// Call this when the view disappears.
    func stopObserving() {
        notificationTask?.cancel()
        notificationTask = nil
    }
}
