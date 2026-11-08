import SwiftUI
import DesignSystem
import SharedUI
import Utilities
import Domain

struct AccountRow: View {
    let account: AccountEntry
    let monthlyIncome: Decimal
    let currency: String
    /// Types the type menu offers (the primary role can't be reassigned).
    let assignableTypes: [AccountType]
    let canAssignEmergency: Bool

    let onTypeChange: (AccountType) -> Void
    let onNameChange: (String) -> Void
    let onMultiplierChange: ((Double) -> Void)?
    let onHardCapChange: ((Decimal?) -> Void)?
    let onBalanceChange: ((Decimal) -> Void)?
    let onPrimarySavingsToggle: (() -> Void)?
    let onDelete: (() -> Void)?

    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var isExpanded = false
    @FocusState private var isNameFocused: Bool
    @Namespace private var glassNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // Single glass surface that morphs as content expands/collapses
        GlassEffectContainer(spacing: 0) {
            VStack(spacing: 0) {
                mainRow

                if isExpanded && shouldShowExpandedContent {
                    expandedContent
                }
            }
            .glassEffect(in: .rect(cornerRadius: CornerRadius.large))
            .glassEffectID("card-\(account.id)", in: glassNamespace)
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Main Row

private extension AccountRow {
    var mainRow: some View {
        mainRowLayout {
            // At accessibility sizes the decorative icon is dropped and the
            // buttons move under the name so nothing is pushed off-screen.
            if !dynamicTypeSize.isAccessibilitySize {
                accountIcon
            }
            accountContent
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer()
            }
            trailingContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .contentShape(Rectangle())
        .onTapGesture {
            // Convenience for sighted users; VoiceOver uses the chevron button.
            if shouldShowExpandedContent {
                toggleExpanded()
            }
        }
    }

    func toggleExpanded() {
        withAnimation(reduceMotion ? nil : .bouncy) {
            isExpanded.toggle()
        }
        HapticManager.lightTap()
    }

    var accountIcon: some View {
        ZStack {
            Circle()
                .fill(account.accountType.color.opacity(Opacity.light))
                .frame(width: ComponentSize.minTouchTarget, height: ComponentSize.minTouchTarget)

            Image(systemName: account.accountType.icon)
                .font(.title3)
                .foregroundStyle(account.accountType.color)
        }
        .accessibilityHidden(true)
    }

    var accountContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            nameSection
            typeAndBadgesSection
        }
    }

    var nameSection: some View {
        Group {
            if isEditing {
                nameTextField
            } else {
                nameDisplay
            }
        }
    }

    var nameTextField: some View {
        TextField("Account name".localized, text: $editedName)
            .font(.headline)
            .textFieldStyle(.plain)
            .submitLabel(.done)
            .focused($isNameFocused)
            .onAppear { isNameFocused = true }
            .onSubmit { commitName() }
            .onChange(of: isNameFocused) { _, isFocused in
                // Losing focus (e.g. to another field) commits too, not only Return.
                if !isFocused { commitName() }
            }
    }

    var nameDisplay: some View {
        Button {
            editedName = account.name
            isEditing = true
        } label: {
            nameLayout {
                Text(account.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                if account.isPrimary {
                    primaryBadge
                        .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
                }

                if account.isPrimarySavings {
                    primarySavingsBadge
                        .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Double tap to rename".localized)
    }

    func commitName() {
        guard isEditing else { return }
        onNameChange(editedName)
        isEditing = false
    }

    var mainRowLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.sm))
            : AnyLayout(HStackLayout(spacing: Spacing.md))
    }

    /// Badges wrap under the name at accessibility sizes.
    var nameLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xxs))
            : AnyLayout(HStackLayout(spacing: Spacing.xs))
    }

    @ViewBuilder
    var typeAndBadgesSection: some View {
        // The primary account's role is fixed (its "Primary" badge already says so),
        // so it gets no type menu.
        if !account.isPrimary {
            AccountTypeSelector(
                selectedType: .init(
                    get: { account.accountType },
                    set: { onTypeChange($0) }
                ),
                types: assignableTypes,
                compact: true,
                disableEmergency: !canAssignEmergency
            )
        }
    }

    var trailingContent: some View {
        HStack(spacing: Spacing.sm) {
            if shouldShowExpandedContent {
                expandChevron
                    .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
            }
            deleteButton
        }
    }

    var expandChevron: some View {
        Button {
            toggleExpanded()
        } label: {
            Image(systemName: "chevron.down")
                .font(.caption)
                .foregroundStyle(.secondary)
                .rotationEffect(isExpanded ? .degrees(180) : .zero)
                .animation(.easeOut(duration: AnimationDuration.appear), value: isExpanded)
                .frame(minWidth: ComponentSize.minTouchTarget, minHeight: ComponentSize.minTouchTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? "Hide details".localized : "Show details".localized)
    }

    @ViewBuilder
    var deleteButton: some View {
        if let onDelete {
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .frame(minWidth: ComponentSize.minTouchTarget, minHeight: ComponentSize.minTouchTarget)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "Remove \(account.name)", bundle: .module))
        }
    }
}

// MARK: - Badges

private extension AccountRow {
    var primaryBadge: some View {
        Text("Primary".localized)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(DiamerisColors.accentPrimary.opacity(Opacity.light))
            .clipShape(Capsule())
    }

    var primarySavingsBadge: some View {
        Text("Auto-Save".localized)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(DiamerisColors.accentSecondary.opacity(Opacity.light))
            .clipShape(Capsule())
    }
}

// MARK: - Expanded Content

private extension AccountRow {
    var shouldShowExpandedContent: Bool {
        account.accountType == .emergency || account.accountType == .savings
    }

    @ViewBuilder
    var expandedContent: some View {
        VStack(spacing: Spacing.md) {
            Divider()
                .padding(.horizontal, Spacing.md)

            VStack(spacing: Spacing.md) {
                if account.accountType == .emergency {
                    emergencyExpandedContent
                } else if account.accountType == .savings {
                    savingsExpandedContent
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.md)
        }
    }

    var emergencyExpandedContent: some View {
        VStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Target: months of income".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                EmergencyMultiplierPicker(
                    multiplier: Binding(
                        get: { account.emergencyMultiplier ?? EmergencyMultiplierPicker.defaultMultiplier },
                        set: { onMultiplierChange?($0) }
                    ),
                    hardCap: Binding(
                        get: { account.emergencyHardCap },
                        set: { onHardCapChange?($0) }
                    ),
                    monthlyIncome: monthlyIncome,
                    currency: currency
                )
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Current balance".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                BalanceInputField(
                    balance: Binding(
                        get: { account.currentBalance },
                        set: { onBalanceChange?($0) }
                    ),
                    currency: currency
                )
            }

            if let progress = account.emergencyProgress(monthlyIncome: monthlyIncome) {
                emergencyProgressView(progress: progress)
                    .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
            }
        }
    }

    func emergencyProgressView(progress: Double) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("Progress".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(progress, format: .percent.precision(.fractionLength(0)))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(progress >= 1.0 ? .green : .orange)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: AnimationDuration.appear), value: progress)
            }

            ProgressView(value: progress)
                .tint(progress >= 1.0 ? .green : .orange)
                .animation(.easeOut(duration: AnimationDuration.appear), value: progress)
        }
    }

    var savingsExpandedContent: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if !account.isPrimarySavings, let onToggle = onPrimarySavingsToggle {
                Button {
                    onToggle()
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)

                        Text("Set as Primary Savings".localized)
                            .font(.subheadline)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
            } else if account.isPrimarySavings {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Text("This account receives automatic savings".localized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
            }
        }
    }
}

// MARK: - Balance Input Field

private struct BalanceInputField: View {
    @Binding var balance: Decimal
    let currency: String

    @State private var text: String = ""

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text(currency)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            TextField("0", text: $text)
                .font(.subheadline)
                .accessibilityLabel("Current balance".localized)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .onChange(of: text) { _, newValue in
                    balance = AmountFormatter.parse(newValue)
                }
                .onAppear {
                    if balance > 0 {
                        text = AmountFormatter.formatForEditing(balance)
                    }
                }
        }
        .padding(Spacing.sm)
        .background(Color.secondary.opacity(Opacity.faint))
        .clipShape(.rect(cornerRadius: CornerRadius.small))
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        AccountRow(
            account: .primary(),
            monthlyIncome: 5000,
            currency: "USD",
            assignableTypes: OnboardingViewModel.assignableAccountTypes,
            canAssignEmergency: true,
            onTypeChange: { _ in },
            onNameChange: { _ in },
            onMultiplierChange: nil,
            onHardCapChange: nil,
            onBalanceChange: nil,
            onPrimarySavingsToggle: nil,
            onDelete: nil
        )

        AccountRow(
            account: .emergency(multiplier: 3.0, currentBalance: 5000),
            monthlyIncome: 5000,
            currency: "USD",
            assignableTypes: OnboardingViewModel.assignableAccountTypes,
            canAssignEmergency: false,
            onTypeChange: { _ in },
            onNameChange: { _ in },
            onMultiplierChange: { _ in },
            onHardCapChange: { _ in },
            onBalanceChange: { _ in },
            onPrimarySavingsToggle: nil,
            onDelete: { }
        )

        AccountRow(
            account: .savings(isPrimarySavings: true),
            monthlyIncome: 5000,
            currency: "USD",
            assignableTypes: OnboardingViewModel.assignableAccountTypes,
            canAssignEmergency: false,
            onTypeChange: { _ in },
            onNameChange: { _ in },
            onMultiplierChange: nil,
            onHardCapChange: nil,
            onBalanceChange: nil,
            onPrimarySavingsToggle: { },
            onDelete: { }
        )
    }
    .padding()
}
