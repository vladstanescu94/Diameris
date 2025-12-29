import SwiftUI
import DesignSystem
import SharedUI
import Utilities
import Domain

/// A row displaying an account with editable properties based on account type.
struct AccountRow: View {
    let account: AccountEntry
    let monthlyIncome: Decimal
    let currency: String
    let hasExistingEmergency: Bool

    let onTypeChange: (AccountType) -> Void
    let onNameChange: (String) -> Void
    let onMultiplierChange: ((Double) -> Void)?
    let onBalanceChange: ((Decimal) -> Void)?
    let onPrimarySavingsToggle: (() -> Void)?
    let onDelete: (() -> Void)?

    @State private var isEditing = false
    @State private var editedName: String = ""
    @State private var isExpanded = false
    @Namespace private var glassNamespace

    var body: some View {
        // Single glass surface that morphs as content expands/collapses
        GlassEffectContainer(spacing: 0) {
            VStack(spacing: 0) {
                mainRow

                if isExpanded {
                    expandedContent
                }
            }
            .glassEffect(in: .rect(cornerRadius: CornerRadius.large))
            .glassEffectID("card-\(account.id)", in: glassNamespace)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
}

// MARK: - Main Row

private extension AccountRow {
    var mainRow: some View {
        HStack(spacing: Spacing.md) {
            accountIcon
            accountContent
            Spacer()
            trailingContent
        }
        .padding(Spacing.md)
        .contentShape(Rectangle())
        .onTapGesture {
            if shouldShowExpandedContent {
                withAnimation(.bouncy) {
                    isExpanded.toggle()
                }
                HapticManager.lightTap()
            }
        }
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
            .onSubmit {
                onNameChange(editedName)
                isEditing = false
            }
    }

    var nameDisplay: some View {
        HStack(spacing: Spacing.xs) {
            Text(account.name)
                .font(.headline)

            if account.isPrimary {
                primaryBadge
                    .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
            }

            if account.isPrimarySavings {
                primarySavingsBadge
                    .transition(.opacity.animation(.easeOut(duration: AnimationDuration.appear)))
            }
        }
        .onTapGesture {
            editedName = account.name
            isEditing = true
        }
    }

    var typeAndBadgesSection: some View {
        AccountTypeSelector(
            selectedType: .init(
                get: { account.accountType },
                set: { onTypeChange($0) }
            ),
            compact: true,
            disableEmergency: hasExistingEmergency
        )
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

    @ViewBuilder
    var expandChevron: some View {
        Image(systemName: "chevron.down")
            .font(.caption)
            .foregroundStyle(.secondary)
            .rotationEffect(.degrees(isExpanded ? 180 : 0))
            .animation(.easeOut(duration: AnimationDuration.appear), value: isExpanded)
    }

    @ViewBuilder
    var deleteButton: some View {
        if let onDelete = onDelete {
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
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
            .foregroundStyle(DiamerisColors.accentPrimary)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(DiamerisColors.accentPrimary.opacity(0.15))
            .clipShape(Capsule())
    }

    var primarySavingsBadge: some View {
        Text("Auto-Save".localized)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(DiamerisColors.accentSecondary)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(DiamerisColors.accentSecondary.opacity(0.15))
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
        // GlassEffectContainer handles the morphing animation
    }

    var emergencyExpandedContent: some View {
        VStack(spacing: Spacing.md) {
            // Multiplier Picker
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Target: months of income".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                EmergencyMultiplierPicker(
                    multiplier: Binding(
                        get: { account.emergencyMultiplier ?? 3.0 },
                        set: { onMultiplierChange?($0) }
                    ),
                    monthlyIncome: monthlyIncome,
                    currency: currency
                )
            }

            // Current Balance
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

            // Progress Display
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

                Text("\(Int(progress * 100))%")
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

// MARK: - Accessibility

private extension AccountRow {
    var accessibilityDescription: String {
        var description = "\(account.name), \(account.accountType.displayName)"

        if account.isPrimary {
            description += ", primary account"
        }

        if account.isPrimarySavings {
            description += ", primary savings"
        }

        if account.accountType == .emergency, let target = account.emergencyTarget(monthlyIncome: monthlyIncome) {
            description += ", target \(AmountFormatter.formatForDisplay(target, currency: currency))"
        }

        return description
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
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        AccountRow(
            account: .primary(),
            monthlyIncome: 5000,
            currency: "USD",
            hasExistingEmergency: false,
            onTypeChange: { _ in },
            onNameChange: { _ in },
            onMultiplierChange: nil,
            onBalanceChange: nil,
            onPrimarySavingsToggle: nil,
            onDelete: nil
        )

        AccountRow(
            account: .emergency(multiplier: 3.0, currentBalance: 5000),
            monthlyIncome: 5000,
            currency: "USD",
            hasExistingEmergency: true,
            onTypeChange: { _ in },
            onNameChange: { _ in },
            onMultiplierChange: { _ in },
            onBalanceChange: { _ in },
            onPrimarySavingsToggle: nil,
            onDelete: { }
        )

        AccountRow(
            account: .savings(isPrimarySavings: true),
            monthlyIncome: 5000,
            currency: "USD",
            hasExistingEmergency: true,
            onTypeChange: { _ in },
            onNameChange: { _ in },
            onMultiplierChange: nil,
            onBalanceChange: nil,
            onPrimarySavingsToggle: { },
            onDelete: { }
        )
    }
    .padding()
}
