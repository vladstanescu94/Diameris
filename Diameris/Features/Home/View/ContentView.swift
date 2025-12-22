//
//  ContentView.swift
//  Diameris
//
//  Created by Vlad Stanescu on 22.12.2025.
//

import SwiftUI
import SwiftData
import DesignSystem

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        NavigationSplitView {
            List {
                // MARK: - Welcome Header (DesignSystem Demo)
                Section {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("Welcome to Diameris")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(DiamerisColors.accentPrimaryLight)

                        Text("Your personal finance companion")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, Spacing.xs)
                }

                // MARK: - Items List
                Section("Items") {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        } label: {
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            // MARK: - Detail View (DesignSystem Demo)
            VStack(spacing: Spacing.lg) {
                Image(systemName: "chart.pie.fill")
                    .iconXxl()
                    .foregroundStyle(DiamerisColors.accentSecondaryLight)

                Text("Select an item")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
