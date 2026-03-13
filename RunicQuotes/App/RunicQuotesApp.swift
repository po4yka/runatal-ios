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
    @AppStorage(AppConstants.onboardingCompletedKey) private var hasCompletedOnboarding = false
    @AppStorage(AppConstants.selectedThemeStorageKey) private var selectedThemeRaw = AppTheme.obsidian.rawValue
    @State private var showDatabaseError = false
    @State private var databaseErrorMessage = ""
    @State private var showOnboarding = false

    // MARK: - Initialization

    init() {
        do {
            let container = try ModelContainerHelper.createMainContainer()
            modelContainer = container

            // Seed database on first launch, then purge expired soft-deleted quotes
            Task { [container] in
                do {
                    try await DatabaseActor.shared.seedIfNeeded(using: container)
                } catch {
                    Self.logger.error("Failed to seed database: \(error.localizedDescription)")
                }
                await DatabaseActor.shared.purgeExpiredQuotes(using: container)
                await DatabaseActor.shared.backfillTranslations(using: container)
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

    private var selectedTheme: AppTheme {
        AppTheme.fromStorage(selectedThemeRaw)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }

                // Show error banner if database initialization failed
                if showDatabaseError {
                    VStack {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text(databaseErrorMessage)
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .clipShape(.rect(cornerRadius: 8))
                        .padding(.top, 50)

                        Spacer()
                    }
                }
            }
            .modelContainer(modelContainer)
            .environment(\.runicTheme, selectedTheme)
            .animation(DesignTokens.Motion.themeTransition, value: selectedThemeRaw)
            .task {
                await syncThemeFromPreferences()
                guard !hasCompletedOnboarding else { return }
                showOnboarding = true
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView {
                    hasCompletedOnboarding = true
                    showOnboarding = false
                }
            }
        }
    }

    @MainActor
    private func syncThemeFromPreferences() async {
        do {
            let preferences = try UserPreferences.getOrCreate(in: modelContainer.mainContext)
            let storedTheme = preferences.selectedTheme.rawValue
            if selectedThemeRaw != storedTheme {
                selectedThemeRaw = storedTheme
            }
        } catch {
            Self.logger.error("Failed to sync selected theme: \(error.localizedDescription)")
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

/// Main tab view with Home, Collections, Search, Saved, and Settings screens.
struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @StateObject private var searchCoordinator = AppSearchCoordinator()
    @StateObject private var homeAccessoryController = HomeAccessoryController()

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.title, systemImage: tab.systemImage, value: tab, role: tab.role) {
                    tabContent(for: tab)
                        .environmentObject(searchCoordinator)
                        .environmentObject(homeAccessoryController)
                }
                .accessibilityIdentifier(tab.accessibilityID)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .searchable(
            text: $searchCoordinator.query,
            isPresented: $searchCoordinator.isPresented,
            prompt: "Quotes, authors, themes..."
        )
        .tabViewBottomAccessory {
            if selectedTab.supportsBottomAccessory && homeAccessoryController.isVisible {
                HomeBottomAccessoryView {
                    NotificationCenter.default.post(name: .loadNextQuote, object: nil)
                }
                .environmentObject(homeAccessoryController)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToTab)) { notification in
            if let tab = notification.userInfo?["tab"] as? AppTab {
                selectedTab = tab
                searchCoordinator.isPresented = tab == .search
            }
            // Forward collection selection if included (e.g. from CollectionsView)
            if let collection = notification.userInfo?["collection"] as? QuoteCollection {
                NotificationCenter.default.post(
                    name: .preferencesDidChange,
                    object: nil,
                    userInfo: ["collection": collection]
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToQuoteTab)) { _ in
            selectedTab = .home
            searchCoordinator.isPresented = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToSettingsTab)) { _ in
            selectedTab = .settings
        }
        .onChange(of: selectedTab) { _, newTab in
            searchCoordinator.isPresented = newTab == .search
            if newTab != .home { homeAccessoryController.hide() }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        NavigationStack {
            switch tab {
            case .home:
                QuoteView()
            case .collections:
                CollectionsView()
            case .search:
                SearchView()
            case .saved:
                SavedView()
            case .settings:
                SettingsView()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
