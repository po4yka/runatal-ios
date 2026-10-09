//
//  QuoteView.swift
//  RunicQuotes
//
//  Created by Claude on 07.10.25.
//

import Combine
import SwiftData
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif
#if canImport(AppKit)
    import AppKit
#endif

// swiftlint:disable type_body_length
/// Main view for displaying runic quotes
struct QuoteView: View {
    // MARK: - Properties

    private static let shouldOpenTranslationOnLaunchForUITests =
        ProcessInfo.processInfo.environment["UI_TEST_OPEN_TRANSLATION"] == "1"

    @StateObject private var viewModel: QuoteViewModel
    @State private var didInitialize = false
    @State private var isRouteConsumerReady = false
    @State private var isScriptMorphing = false
    @State private var showQuoteSource = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scriptMorphTask: Task<Void, Never>?
    @State private var showShareView = false
    @State private var showCreateQuote = false
    @State private var showCreateChoices = false
    @State private var showTranslationView = false
    @State private var showActionsSheet = false
    @State private var showDeleteConfirmation = false
    @State private var editingQuoteRecord: QuoteRecord?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @EnvironmentObject private var navigationCoordinator: QuoteNavigationCoordinator
    @EnvironmentObject private var homeAccessoryController: HomeAccessoryController
    @EnvironmentObject private var featureDiscoveryController: FeatureDiscoveryController
    private let createEditQuoteViewBuilder: CreateEditQuoteViewBuilder
    private let translationViewBuilder: TranslationViewBuilder

    // MARK: - Initialization

    init(
        viewModel: QuoteViewModel,
        createEditQuoteViewBuilder: CreateEditQuoteViewBuilder,
        translationViewBuilder: TranslationViewBuilder,
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.createEditQuoteViewBuilder = createEditQuoteViewBuilder
        self.translationViewBuilder = translationViewBuilder
    }

    // MARK: - Body

    var body: some View {
        self.presentedContent
    }

    private var lifecycleAwareContent: some View {
        self.rootContent
            .task {
                self.viewModel.onAppear()
                self.isRouteConsumerReady = true
                self.openPendingQuoteIfReady()
                guard !self.didInitialize else { return }
                self.didInitialize = true
                if Self.shouldOpenTranslationOnLaunchForUITests {
                    self.showTranslationView = true
                }
            }
            .onChange(of: self.viewModel.state.currentScript) { _, _ in
                self.startScriptMorphTransition()
            }
            .onReceive(NotificationCenter.default.publisher(for: .preferencesDidChange).receive(on: RunLoop.main)) { notification in
                if let collection = notification.userInfo?["collection"] as? QuoteCollection {
                    self.viewModel.onCollectionChanged(collection)
                } else {
                    self.viewModel.onPreferencesChanged()
                }
            }
            .onReceive(self.navigationCoordinator.$pendingRequest.receive(on: RunLoop.main)) { _ in self.openPendingQuoteIfReady() }
            .onReceive(NotificationCenter.default.publisher(for: .loadNextQuote)) { _ in
                self.handleNextQuoteTriggered()
            }
            .onReceive(NotificationCenter.default.publisher(for: .libraryDidChange).receive(on: RunLoop.main)) { _ in
                self.viewModel.onLibraryChanged()
            }
            .onReceive(NotificationCenter.default.publisher(for: .translationCacheUpdated).receive(on: RunLoop.main)) { notification in
                let quoteID = notification.userInfo?["quoteID"] as? UUID
                self.viewModel.onTranslationCacheUpdated(for: quoteID)
            }
            .onChange(of: self.viewModel.state.currentCollection) { _, _ in
                self.syncHomeAccessory()
            }
            .onChange(of: self.viewModel.state.currentScript) { _, _ in
                self.syncHomeAccessory()
            }
            .onChange(of: self.viewModel.state.latinText) { _, _ in
                self.syncHomeAccessory()
            }
    }

    private var chromeContent: some View {
        self.lifecycleAwareContent
            .onDisappear {
                self.isRouteConsumerReady = false
                self.viewModel.onDisappear()
                self.scriptMorphTask?.cancel()
                self.scriptMorphTask = nil
                self.homeAccessoryController.hide()
                self.featureDiscoveryController.updateHomeQuoteReady(false)
            }
            .navigationTitle("Home")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar {
                QuoteToolbar(
                    currentCollection: self.viewModel.state.currentCollection,
                    palette: self.palette,
                    openCreateChoices: { self.showCreateChoices = true },
                )
            }
    }

    private var presentedContent: some View {
        self.chromeContent
            .sheet(isPresented: self.$showShareView) {
                NavigationStack {
                    ShareQuoteView(
                        runicText: self.viewModel.state.runicText,
                        latinText: self.viewModel.state.latinText,
                        author: self.viewModel.state.author,
                        script: self.viewModel.state.currentScript,
                        font: self.viewModel.state.currentFont,
                        presentationSource: self.viewModel.state.runicPresentationSource,
                        evidenceTier: self.viewModel.state.runicEvidenceTier,
                        primarySourceLabel: self.viewModel.state.runicPrimarySourceLabel,
                        warnings: self.viewModel.state.runicWarnings,
                        isRunicRenderingAvailable: self.viewModel.state.isRunicRenderingAvailable,
                    )
                }
            }
            .sheet(isPresented: self.$showCreateQuote) {
                NavigationStack {
                    self.createEditQuoteViewBuilder.makeView(mode: .create, onSaved: { id in
                        self.navigationCoordinator.openQuote(id: id, script: nil, mode: nil, collection: nil)
                    })
                }
            }
            .sheet(isPresented: self.$showTranslationView) {
                NavigationStack {
                    self.translationViewBuilder.makeView()
                }
            }
            .confirmationDialog("Create quote", isPresented: self.$showCreateChoices, titleVisibility: .visible) {
                Button(String(localized: "translation.menu.newQuote"), action: self.openQuoteEditor)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(String(localized: "translation.menu.newQuote"))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction(.default, self.openQuoteEditor)
                    .accessibilityIdentifier("quote_create_new_action")
                Button(String(localized: "translation.menu.translate"), action: self.openTranslation)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(String(localized: "translation.menu.translate"))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction(.default, self.openTranslation)
                    .accessibilityIdentifier("quote_create_translate_action")
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog(
                "Current passage",
                isPresented: self.$showActionsSheet,
                titleVisibility: .visible,
            ) {
                ForEach(self.availableQuoteActions) { action in
                    Button(action.title, role: action.isDestructive ? .destructive : nil) {
                        self.handleQuoteAction(action)
                    }
                }
            } message: {
                Text("Choose how this quote should be handled.")
            }
            .sheet(item: self.$editingQuoteRecord) { record in
                NavigationStack {
                    self.createEditQuoteViewBuilder.makeView(mode: .edit(record), onSaved: { id in
                        self.navigationCoordinator.openQuote(id: id, script: nil, mode: nil, collection: nil)
                    })
                }
            }
            .alert("Delete Quote?", isPresented: self.$showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    self.viewModel.deleteCurrentQuote()
                }
            } message: {
                Text("This will move the quote to your archive. You can restore it later from Settings > Archive.")
            }
            .task(id: self.viewModel.state.currentQuoteID) {
                self.syncHomeAccessory()
                self.featureDiscoveryController.updateHomeQuoteReady(self.viewModel.state.currentQuoteID != nil)
            }
    }

    private var rootContent: some View {
        ZStack {
            LiquidContentScaffold(
                palette: self.palette,
                scrollEnabled: !self.viewModel.state.isLoading && self.viewModel.state.errorMessage == nil,
                showBackgroundExtension: true,
            ) {
                if self.viewModel.state.isLoading {
                    QuoteLoadingView(palette: self.palette)
                        .frame(maxWidth: .infinity, minHeight: 480, alignment: .center)
                } else if let error = viewModel.state.errorMessage {
                    QuoteErrorView(message: error, palette: self.palette) {
                        self.viewModel.refresh()
                    }
                    .frame(maxWidth: .infinity, minHeight: 480, alignment: .center)
                } else {
                    self.quoteContentView
                }
            }

            RunicAtmosphere(script: self.viewModel.state.currentScript)
                .ignoresSafeArea()
                .opacity(0.045)
                .allowsHitTesting(false)
        }
    }

    private var palette: AppThemePalette {
        .themed(self.runicTheme, for: self.colorScheme)
    }

    private var decorativeGlyph: String {
        switch self.viewModel.state.currentScript {
        case .elder: "\u{16A0}"
        case .younger: "\u{16A2}"
        case .cirth: "\u{E0B9}"
        }
    }

    private var availableQuoteActions: [QuoteAction] {
        [
            .share,
            self.viewModel.state.isCurrentQuoteSaved ? .removeFromFavorites : .addToFavorites,
            .addToCollection,
            .copyText,
            .edit,
            .hide,
            .delete,
        ]
    }

    // MARK: - Quote Content

    private var quoteContentView: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            HeroHeader(
                eyebrow: "Home",
                title: "Reading",
                subtitle: "One passage, one quiet focal point.",
                meta: [
                    self.viewModel.state.currentCollection.displayName,
                    self.viewModel.state.currentScript.displayName,
                    self.viewModel.state.currentReadingMode.displayName,
                ],
                palette: self.palette,
            )

            self.homeChrome

            QuoteCardSectionView(
                runicText: self.viewModel.state.runicText,
                presentationSource: self.viewModel.state.runicPresentationSource,
                evidenceTier: self.viewModel.state.runicEvidenceTier,
                primarySourceLabel: self.viewModel.state.runicPrimarySourceLabel,
                latinText: self.viewModel.state.latinText,
                author: self.viewModel.state.author,
                script: self.viewModel.state.currentScript,
                font: self.viewModel.state.currentFont,
                warnings: self.viewModel.state.runicWarnings,
                isRunicRenderingAvailable: self.viewModel.state.isRunicRenderingAvailable,
                decorativeGlyph: self.decorativeGlyph,
                palette: self.palette,
                isScriptMorphing: self.isScriptMorphing,
                isSaved: self.viewModel.state.isCurrentQuoteSaved,
                tipRefreshID: self.featureDiscoveryController.refreshID,
                onNextQuote: {
                    self.handleNextQuoteTriggered()
                },
                onToggleSave: {
                    self.handleSaveTriggered()
                },
                onShowActions: {
                    Haptics.trigger(.saveOrShare)
                    self.showActionsSheet = true
                },
            )
            SavedAssessmentSourcesButton(artifact: self.viewModel.state.savedTranslationArtifact)
            if let source = self.viewModel.state.quoteSource, !source.isEmpty {
                Button("Passage source", systemImage: "book.closed") { self.showQuoteSource = true }
                    .accessibilityIdentifier("quote_source_button")
                    .sheet(isPresented: self.$showQuoteSource) { QuoteSourceSheet(source: source) }
            }
            if self.viewModel.state.currentScript == .cirth {
                Text("Cirth uses private-use characters. Copied text needs a compatible font; image sharing preserves its appearance.")
                    .font(.caption)
            }
        }
    }

    private var homeChrome: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            QuoteScriptPickerView(
                palette: self.palette,
                selectedScript: self.viewModel.state.currentScript,
            ) { newScript in
                Haptics.trigger(.scriptSwitch)
                self.viewModel.onScriptChanged(newScript)
            }

            CollectionCoverCarousel(
                covers: self.viewModel.state.collectionCovers,
                selectedCollection: self.viewModel.state.currentCollection,
                script: self.viewModel.state.currentScript,
                font: self.viewModel.state.currentFont,
                palette: self.palette,
            ) { collection in
                guard collection != self.viewModel.state.currentCollection else { return }
                Haptics.trigger(.scriptSwitch)
                self.viewModel.onCollectionChanged(collection)
            }

            Button {
                NotificationCenter.default.post(
                    name: .switchToTab,
                    object: nil,
                    userInfo: ["tab": AppTab.search],
                )
            } label: {
                LiquidCard(
                    palette: self.palette,
                    role: .chrome,
                    cornerRadius: DesignTokens.CornerRadius.xl,
                    shadowRadius: DesignTokens.Elevation.chrome,
                    contentPadding: DesignTokens.Spacing.md,
                    interactive: true,
                ) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(self.palette.subtleAccentText)

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                            Text("Search the library")
                                .font(DesignTokens.Typography.bodyLarge)
                                .foregroundStyle(self.palette.textPrimary)

                            Text("Move into the dedicated Search tab for authors, fragments, and collections.")
                                .font(DesignTokens.Typography.listMeta)
                                .foregroundStyle(self.palette.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(self.palette.subtleAccentText)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("home_open_search_button")
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    private func syncHomeAccessory() {
        guard self.didInitialize else { return }
        self.homeAccessoryController.update(
            collection: self.viewModel.state.currentCollection,
            script: self.viewModel.state.currentScript,
            caption: self.viewModel.state.author.isEmpty ? "Continue reading" : self.viewModel.state.author,
        )
    }

    private func openQuoteEditor() {
        self.showCreateChoices = false
        self.showCreateQuote = true
    }

    private func openTranslation() {
        self.showCreateChoices = false
        self.showTranslationView = true
    }

    private func openPendingQuoteIfReady() {
        guard self.isRouteConsumerReady, let request = self.navigationCoordinator.consumePendingRequest() else { return }
        self.viewModel.onOpenQuoteDeepLink(
            quoteID: request.id,
            scriptRaw: request.script?.rawValue,
            modeRaw: request.mode?.rawValue,
            collectionRaw: request.collection?.rawValue,
        )
    }

    // MARK: - Script Morph Animation

    private func startScriptMorphTransition() {
        self.scriptMorphTask?.cancel()
        guard !self.reduceMotion else { self.isScriptMorphing = false; return }
        self.scriptMorphTask = Task { @MainActor in
            withAnimation(.easeOut(duration: 0.08)) {
                self.isScriptMorphing = !self.reduceMotion
            }

            try? await Task.sleep(for: .milliseconds(90))
            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: 0.22)) {
                self.isScriptMorphing = false
            }
        }
    }

    private func copyCurrentQuote() {
        let payload = "\(viewModel.state.latinText)\n— \(self.viewModel.state.author)"

        #if canImport(UIKit)
            UIPasteboard.general.string = payload
        #elseif canImport(AppKit)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(payload, forType: .string)
        #endif
    }

    // MARK: - Quote Actions

    private func handleNextQuoteTriggered() {
        Haptics.trigger(.newQuote)
        self.viewModel.onNextQuoteTapped()
        FeatureDiscoveryEvents.homeAdvancedQuote.sendDonation()
        HomeNextQuoteTip().invalidate(reason: .actionPerformed)
        self.featureDiscoveryController.recordHomeQuoteAdvanced()
    }

    private func handleSaveTriggered() {
        let wasSaved = self.viewModel.state.isCurrentQuoteSaved
        Haptics.trigger(.saveOrShare)
        self.viewModel.onToggleSaveTapped()

        guard !wasSaved else { return }
        FeatureDiscoveryEvents.homeSavedQuote.sendDonation()
        HomeSaveQuoteTip().invalidate(reason: .actionPerformed)
        self.featureDiscoveryController.recordHomeQuoteSaved()
    }

    private func handleQuoteAction(_ action: QuoteAction) {
        switch action {
        case .share:
            self.showShareView = true
        case .addToFavorites, .removeFromFavorites:
            self.handleSaveTriggered()
        case .addToCollection:
            // Currently quotes belong to one collection set at creation.
            // Open edit flow so the user can change the collection.
            self.editingQuoteRecord = self.viewModel.currentQuoteRecord()
        case .copyText:
            self.copyCurrentQuote()
        case .edit:
            self.editingQuoteRecord = self.viewModel.currentQuoteRecord()
        case .hide:
            self.viewModel.hideCurrentQuote()
        case .delete:
            self.showDeleteConfirmation = true
        }
    }

}

// swiftlint:enable type_body_length
