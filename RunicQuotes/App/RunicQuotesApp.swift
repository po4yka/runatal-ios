//
//  RunicQuotesApp.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI
import SwiftData

@main
struct RunicQuotesApp: App {
    // MARK: - SwiftData Model Container

    let modelContainer: ModelContainer

    // MARK: - Initialization

    init() {
        do {
            // Configure the SwiftData model container
            let schema = Schema([
                Quote.self,
                UserPreferences.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // Seed database on first launch
            Task {
                let context = ModelContext(modelContainer)
                let repository = SwiftDataQuoteRepository(modelContext: context)
                try await repository.seedIfNeeded()
            }
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(modelContainer)
        }
    }
}

/// Main tab view with Quote and Settings screens
struct MainTabView: View {
    var body: some View {
        TabView {
            QuoteView()
                .tabItem {
                    Label("Quote", systemImage: "quote.bubble.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(.white)
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
