import SwiftUI
import DesignSystem

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardPlaceholder()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie.fill")
                }

            BudgetPlaceholder()
                .tabItem {
                    Label("Budget", systemImage: "list.bullet.rectangle")
                }

            GoalsPlaceholder()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }

            TransfersPlaceholder()
                .tabItem {
                    Label("Transfers", systemImage: "arrow.left.arrow.right")
                }

            #if DEBUG
            DevDebugView()
                .tabItem {
                    Label("Dev", systemImage: "hammer.fill")
                }
            #endif
        }
    }
}

// MARK: - Placeholder Views

private struct DashboardPlaceholder: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "chart.pie.fill")
                    .iconXxl()
                    .foregroundStyle(DiamerisColors.accentPrimaryLight)

                Text("Dashboard")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Dashboard")
        }
    }
}

private struct BudgetPlaceholder: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "list.bullet.rectangle")
                    .iconXxl()
                    .foregroundStyle(DiamerisColors.accentSecondaryLight)

                Text("Budget")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Budget")
        }
    }
}

private struct GoalsPlaceholder: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "target")
                    .iconXxl()
                    .foregroundStyle(DiamerisColors.accentPrimaryLight)

                Text("Goals")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Goals")
        }
    }
}

private struct TransfersPlaceholder: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                Image(systemName: "arrow.left.arrow.right")
                    .iconXxl()
                    .foregroundStyle(DiamerisColors.accentSecondaryLight)

                Text("Transfers")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Transfers")
        }
    }
}

#Preview {
    MainTabView()
}
