import UIKit

/// Centralized keyboard management utilities.
public enum KeyboardHelper {
    /// Dismisses the keyboard by resigning the first responder.
    @MainActor
    public static func dismiss() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}
