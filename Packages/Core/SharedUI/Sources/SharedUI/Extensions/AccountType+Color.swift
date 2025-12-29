import SwiftUI
import Domain
import DesignSystem

/// Centralized color mapping for AccountType.
/// All features should use this extension for consistent account type colors.
public extension AccountType {
    /// The color associated with this account type for UI display.
    var color: Color {
        switch self {
        case .primary:
            return DiamerisColors.accentPrimary
        case .emergency:
            return DiamerisColors.warning
        case .savings:
            return DiamerisColors.accentSecondary
        case .personal:
            return .purple
        case .joint:
            return .pink
        case .other:
            return .secondary
        }
    }
}
