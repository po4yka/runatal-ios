//
//  RunicQuotesApp.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI
import SwiftData
import os

@main
struct RunicQuotesApp: App {
    // MARK: - Properties

    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "App")

    let modelContainer: ModelContainer
    @State private var showDatabaseError = false
    @State private var databaseErrorMessage = ""

    // MARK: - Initialization

    init() {
        do {
            let container = try ModelContainerHelper.createMainContainer()
            modelContainer = container

            // Seed database on first launch
            Task { [container] in
                do {
                    try await DatabaseActor.shared.seedIfNeeded(using: container)
                } catch {
                    Self.logger.error("Failed to seed database: \(error.localizedDescription)")
                }
            }
        } catch {
            Self.logger.critical("Failed to create ModelContainer: \(error.localizedDescription)")

            // Fallback to in-memory container
            do {
                Self.logger.info("Attempting to create fallback in-memory container")
                let placeholderContainer = ModelContainerHelper.createPlaceholderContainer()
                modelContainer = placeholderContainer
                databaseErrorMessage = "Using temporary database. Data will not be saved."
                showDatabaseError = true
            }
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .modelContainer(modelContainer)
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }

                // Show error banner if database initialization failed
                if showDatabaseError {
                    VStack {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text(databaseErrorMessage)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.top, 50)

                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Deep Link Handling

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == AppConstants.urlScheme else { return }

        let host = url.host
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        switch host {
        case "quote":
            // Open quote tab and apply optional script/widget mode context.
            let script = components?.queryItems?.first(where: { $0.name == "script" })?.value ?? ""
            let mode = components?.queryItems?.first(where: { $0.name == "mode" })?.value ?? ""

            NotificationCenter.default.post(
                name: .switchToQuoteTab,
                object: nil,
                userInfo: [
                    "script": script,
                    "mode": mode
                ]
            )
        case "settings":
            // Open settings tab
            NotificationCenter.default.post(name: .switchToSettingsTab, object: nil)
        case "next":
            // Load next quote
            NotificationCenter.default.post(name: .loadNextQuote, object: nil)
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
                .accessibilityIdentifier("quote_tab")

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(1)
                .accessibilityIdentifier("settings_tab")
        }
        .tint(.white)
        .onReceive(NotificationCenter.default.publisher(for: .switchToQuoteTab)) { _ in
            selectedTab = 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToSettingsTab)) { _ in
            selectedTab = 1
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
