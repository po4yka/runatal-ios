//
//  RunicQuotesApp.swift
//  RunicQuotes
//
//  Created by Claude on 30.09.25.
//

import os
import SwiftData
import SwiftUI
import UserNotifications

@main
@MainActor
struct RunicQuotesApp: App {
    // MARK: - Properties

    private static let logger = Logger(subsystem: AppConstants.loggingSubsystem, category: "App")

    let modelContainer: ModelContainer
    let rootComponent: AppRootComponent
    let featureDiscoveryController: FeatureDiscoveryController
    @StateObject private var bootstrapViewModel: AppBootstrapViewModel
    @AppStorage(AppConstants.onboardingCompletedKey) private var hasCompletedOnboarding = false
    @AppStorage(AppConstants.selectedThemeStorageKey) private var selectedThemeRaw = AppTheme.obsidian.rawValue
    @State private var showDatabaseError = false
    @State private var databaseErrorMessage = ""
    @State private var showOnboarding = false
    @State private var isMainTabMounted = false
    @State private var didFinishBootstrapPresentation = false

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

        } catch {
            Self.logger.critical("Failed to create ModelContainer: \(error.localizedDescription)")

            // Fallback to in-memory container
            Self.logger.info("Attempting to create fallback in-memory container")
            let placeholderContainer = ModelContainerHelper.createPlaceholderContainer()
            self.modelContainer = placeholderContainer
            self.rootComponent = AppRootComponent(modelContainer: placeholderContainer)
            self.databaseErrorMessage = "Using temporary database. Data will not be saved."
            self.showDatabaseError = true

        }

        _bootstrapViewModel = StateObject(wrappedValue: self.rootComponent.bootstrapViewModel)
        UNUserNotificationCenter.current().delegate = self.rootComponent.dailyReminderNotificationDelegate
        _ = self.rootComponent.widgetRefreshCoordinator
        self.featureDiscoveryController.configureForLaunch(processInfo: .processInfo)
    }

    // MARK: - Body

    private var selectedTheme: AppTheme {
        AppTheme.fromStorage(self.selectedThemeRaw)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch self.bootstrapViewModel.phase {
                case .loading:
                    ProgressView("Preparing your library").accessibilityIdentifier("library_bootstrap_loading")
                case .ready:
                    self.rootComponent.makeMainTabView()
                        .onAppear { self.isMainTabMounted = true; self.openQueuedURLsIfReady() }
                        .onDisappear { self.isMainTabMounted = false }
                case .failed(let message):
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Text("Your library could not be prepared")
                        Text(message)
                        Button("Try again") { Task { await self.bootstrapViewModel.prepare() } }
                    }.accessibilityIdentifier("library_bootstrap_error")
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
            .onOpenURL { self.bootstrapViewModel.enqueue($0) }
            .onChange(of: self.bootstrapViewModel.pendingURLs) { _, _ in self.openQueuedURLsIfReady() }
            .onChange(of: self.bootstrapViewModel.phase) { _, phase in
                if phase == .ready {
                    self.openQueuedURLsIfReady(); Task { await self.finishBootstrapPresentation() }
                }
            }
            .modelContainer(self.modelContainer)
            .environment(\.userPreferencesRepository, self.rootComponent.preferencesRepository)
            .environment(\.runicTheme, self.selectedTheme)
            .environmentObject(self.featureDiscoveryController)
            .environmentObject(self.rootComponent.dailyReminderViewModel)
            .environmentObject(self.rootComponent.navigationCoordinator)
            .animation(DesignTokens.Motion.themeTransition, value: self.selectedThemeRaw)
            .task { await self.bootstrapViewModel.prepare() }
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
    private func finishBootstrapPresentation() async {
        guard !self.didFinishBootstrapPresentation else { return }
        self.didFinishBootstrapPresentation = true
        if self.shouldSkipOnboarding {
            self.hasCompletedOnboarding = true; self.showOnboarding = false
        }
        self.featureDiscoveryController.updateOnboardingCompleted(self.hasCompletedOnboarding)
        await self.syncThemeFromPreferences()
        await self.rootComponent.dailyReminderViewModel.onAppear()
        self.showOnboarding = !self.hasCompletedOnboarding
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

    private func openQueuedURLsIfReady() {
        guard self.bootstrapViewModel.phase == .ready, self.isMainTabMounted else { return }
        for url in self.bootstrapViewModel.consumePendingURLs() {
            self.handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard let link = DeepLink.from(url: url) else { return }
        switch link {
        case .openQuote(let id, let script, let mode, let collection):
            self.rootComponent.navigationCoordinator.openQuote(id: id, script: script, mode: mode, collection: collection)
        case .openDailyQuote(let script):
            self.rootComponent.navigationCoordinator.openQuote(id: nil, script: script, mode: .daily, collection: nil)
        case .nextQuote:
            self.rootComponent.navigationCoordinator.openQuote(id: nil, script: nil, mode: .random, collection: nil)
        case .openSettings: NotificationCenter.default.post(name: .switchToSettingsTab, object: nil)
        case .openApp: NotificationCenter.default.post(name: .switchToQuoteTab, object: nil)
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
            if newTab != .home {
                self.homeAccessoryController.hide()
            }
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
