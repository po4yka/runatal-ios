//
//  RunicQuotesApp.swift
//  RunicQuotes
//
//  Created by Claude on 30.09.25.
//

import os
import SwiftData
import SwiftUI

@main
@MainActor
struct RunicQuotesApp: App {
    // MARK: - Properties

    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "App")

    let modelContainer: ModelContainer
    let rootComponent: AppRootComponent
    let featureDiscoveryController: FeatureDiscoveryController
    @AppStorage(AppConstants.onboardingCompletedKey) private var hasCompletedOnboarding = false
    @AppStorage(AppConstants.selectedThemeStorageKey) private var selectedThemeRaw = AppTheme.obsidian.rawValue
    @State private var showDatabaseError = false
    @State private var databaseErrorMessage = ""
    @State private var showOnboarding = false

    private var shouldSkipOnboarding: Bool {
        ProcessInfo.processInfo.environment["SKIP_ONBOARDING"] == "1"
    }

    // MARK: - Initialization

    init() {
        registerProviderFactories()
        UITestPersistentStoreConfigurator.prepareIfNeeded()
        let featureDiscoveryController = FeatureDiscoveryController()
        self.featureDiscoveryController = featureDiscoveryController

        do {
            let container = try ModelContainerHelper.createMainContainer()
            self.modelContainer = container
            self.rootComponent = AppRootComponent(modelContainer: container)

            // Seed database on first launch, then purge expired soft-deleted quotes
            let databaseCoordinator = self.rootComponent.databaseCoordinator
            Task {
                do {
                    try await databaseCoordinator.seedIfNeeded()
                } catch {
                    Self.logger.error("Failed to seed database: \(error.localizedDescription)")
                }
                await databaseCoordinator.purgeExpiredQuotes()
                await databaseCoordinator.backfillTranslations()
            }
        } catch {
            Self.logger.critical("Failed to create ModelContainer: \(error.localizedDescription)")

            // Fallback to in-memory container
            Self.logger.info("Attempting to create fallback in-memory container")
            let placeholderContainer = ModelContainerHelper.createPlaceholderContainer()
            self.modelContainer = placeholderContainer
            self.rootComponent = AppRootComponent(modelContainer: placeholderContainer)
            self.databaseErrorMessage = "Using temporary database. Data will not be saved."
            self.showDatabaseError = true

            let databaseCoordinator = self.rootComponent.databaseCoordinator
            Task {
                do {
                    try await databaseCoordinator.seedIfNeeded()
                } catch {
                    Self.logger.error("Failed to seed fallback database: \(error.localizedDescription)")
                }
                await databaseCoordinator.backfillTranslations()
            }
        }

        self.featureDiscoveryController.configureForLaunch(processInfo: .processInfo)
    }

    // MARK: - Body

    private var selectedTheme: AppTheme {
        AppTheme.fromStorage(self.selectedThemeRaw)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                self.rootComponent.makeMainTabView()
                    .onOpenURL { url in
                        self.handleDeepLink(url)
                    }

                // Show error banner if database initialization failed
                if self.showDatabaseError {
                    VStack {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.yellow)
                            Text(self.databaseErrorMessage)
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                        .accessibilityIdentifier("database_error_banner")
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .clipShape(.rect(cornerRadius: 8))
                        .padding(.top, 50)

                        Spacer()
                    }
                }
            }
            .modelContainer(self.modelContainer)
            .environment(\.userPreferencesRepository, self.rootComponent.preferencesRepository)
            .environment(\.runicTheme, self.selectedTheme)
            .environmentObject(self.featureDiscoveryController)
            .animation(DesignTokens.Motion.themeTransition, value: self.selectedThemeRaw)
            .task {
                if self.shouldSkipOnboarding {
                    self.hasCompletedOnboarding = true
                    self.showOnboarding = false
                }

                self.featureDiscoveryController.updateOnboardingCompleted(self.hasCompletedOnboarding)
                await self.syncThemeFromPreferences()
                guard !self.hasCompletedOnboarding else { return }
                self.showOnboarding = true
            }
            .onChange(of: self.hasCompletedOnboarding) { _, hasCompletedOnboarding in
                self.featureDiscoveryController.updateOnboardingCompleted(hasCompletedOnboarding)
            }
            .fullScreenCover(isPresented: self.$showOnboarding) {
                self.rootComponent.makeOnboardingView {
                    self.hasCompletedOnboarding = true
                    self.featureDiscoveryController.updateOnboardingCompleted(true)
                    self.showOnboarding = false
                }
            }
        }
    }

    @MainActor
    private func syncThemeFromPreferences() async {
        do {
            let storedTheme = try rootComponent.preferencesRepository.snapshot().selectedTheme.rawValue
            if self.selectedThemeRaw != storedTheme {
                self.selectedThemeRaw = storedTheme
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
                    "mode": mode,
                ],
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
    @StateObject private var searchCoordinator: AppSearchCoordinator
    @StateObject private var homeAccessoryController: HomeAccessoryController
    private let quoteView: QuoteView
    private let searchView: SearchView
    private let savedView: SavedView
    private let settingsView: SettingsView

    init(
        searchCoordinator: AppSearchCoordinator,
        homeAccessoryController: HomeAccessoryController,
        quoteView: QuoteView,
        searchView: SearchView,
        savedView: SavedView,
        settingsView: SettingsView,
    ) {
        _searchCoordinator = StateObject(wrappedValue: searchCoordinator)
        _homeAccessoryController = StateObject(wrappedValue: homeAccessoryController)
        self.quoteView = quoteView
        self.searchView = searchView
        self.savedView = savedView
        self.settingsView = settingsView
    }

    var body: some View {
        TabView(selection: self.$selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(tab.title, systemImage: tab.systemImage, value: tab, role: tab.role) {
                    self.tabContent(for: tab)
                        .environmentObject(self.searchCoordinator)
                        .environmentObject(self.homeAccessoryController)
                }
                .accessibilityIdentifier(tab.accessibilityID)
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .searchable(
            text: self.$searchCoordinator.query,
            isPresented: self.$searchCoordinator.isPresented,
            prompt: "Quotes, authors, themes...",
        )
        .tabViewBottomAccessory {
            if self.selectedTab.supportsBottomAccessory && self.homeAccessoryController.isVisible {
                HomeBottomAccessoryView {
                    NotificationCenter.default.post(name: .loadNextQuote, object: nil)
                }
                .environmentObject(self.homeAccessoryController)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToTab)) { notification in
            if let tab = notification.userInfo?["tab"] as? AppTab {
                self.selectedTab = tab
                self.searchCoordinator.isPresented = tab == .search
            }
            // Forward collection selection if included (e.g. from CollectionsView)
            if let collection = notification.userInfo?["collection"] as? QuoteCollection {
                NotificationCenter.default.post(
                    name: .preferencesDidChange,
                    object: nil,
                    userInfo: ["collection": collection],
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToQuoteTab)) { _ in
            self.selectedTab = .home
            self.searchCoordinator.isPresented = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToSettingsTab)) { _ in
            self.selectedTab = .settings
        }
        .onChange(of: self.selectedTab) { _, newTab in
            self.searchCoordinator.isPresented = newTab == .search
            if newTab != .home { self.homeAccessoryController.hide() }
        }
    }

    // MARK: - Tab Content

    private func tabContent(for tab: AppTab) -> some View {
        NavigationStack {
            switch tab {
            case .home:
                self.quoteView
            case .collections:
                CollectionsView()
            case .search:
                self.searchView
            case .saved:
                self.savedView
            case .settings:
                self.settingsView
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView(
        searchCoordinator: AppSearchCoordinator(),
        homeAccessoryController: HomeAccessoryController(),
        quoteView: QuoteView(
            viewModel: QuoteViewModel.preview(),
            createEditQuoteViewBuilder: CreateEditQuoteViewBuilder { mode, onSaved in
                CreateEditQuoteView(
                    viewModel: CreateEditQuoteViewModel.preview(mode: mode),
                    mode: mode,
                    onSaved: onSaved,
                )
            },
            translationViewBuilder: TranslationViewBuilder {
                TranslationView(viewModel: TranslationViewModel.preview())
            },
        ),
        searchView: SearchView(viewModel: SearchViewModel.preview()),
        savedView: SavedView(viewModel: SavedQuotesViewModel.preview()),
        settingsView: SettingsView(
            viewModel: SettingsViewModel.preview(),
            translationViewBuilder: TranslationViewBuilder {
                TranslationView(viewModel: TranslationViewModel.preview())
            },
            archiveViewBuilder: ArchiveViewBuilder {
                ArchiveView(viewModel: ArchiveViewModel.preview())
            },
        ),
    )
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
    .environmentObject(FeatureDiscoveryController.preview())
}
