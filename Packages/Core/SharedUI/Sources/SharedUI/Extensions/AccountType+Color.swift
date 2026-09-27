import SwiftUI
import Domain
import DesignSystem

/// The one place account types get their colors — features should not define their own.
public extension AccountType {
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
