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
            // Configure the SwiftData model container with App Group
            let schema = Schema([
                Quote.self,
                UserPreferences.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier("group.com.po4yka.runicquotes")
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
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    // MARK: - Deep Link Handling

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "runicquotes" else { return }

        let host = url.host
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        switch host {
        case "quote":
            // Open quote tab and optionally change script
            NotificationCenter.default.post(
                name: Notification.Name("SwitchToQuoteTab"),
                object: nil,
                userInfo: ["script": components?.queryItems?.first(where: { $0.name == "script" })?.value ?? ""]
            )
        case "settings":
            // Open settings tab
            NotificationCenter.default.post(name: Notification.Name("SwitchToSettingsTab"), object: nil)
        case "next":
            // Load next quote
            NotificationCenter.default.post(name: Notification.Name("LoadNextQuote"), object: nil)
        default:
            break
        }
    }
}

/// Main tab view with Quote and Settings screens
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            QuoteView()
                .tabItem {
                    Label("Quote", systemImage: "quote.bubble.fill")
                }
                .tag(0)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(1)
        }
        .tint(.white)
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SwitchToQuoteTab"))) { _ in
            selectedTab = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("SwitchToSettingsTab"))) { _ in
            selectedTab = 1
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
