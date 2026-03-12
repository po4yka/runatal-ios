//
//  QuoteView.swift
//  RunicQuotes
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Main view for displaying runic quotes
struct QuoteView: View {
    // MARK: - Properties

    @StateObject private var viewModel: QuoteViewModel
    @State private var didInitialize = false
    @State private var isScriptMorphing = false
    @State private var scriptMorphTask: Task<Void, Never>?
    @State private var showShareView = false
    @State private var showCreateQuote = false
    @State private var showActionsSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showEditQuote = false
    @State private var searchQuery = ""
    @State private var showCoachMarks = false
    @State private var lastKnownScrollOffset: CGFloat = 0
    @AppStorage(AppConstants.featureTourCompletedKey) private var hasCompletedFeatureTour = false
    @State private var quoteCardAppearScale: CGFloat = 1.0
    @State private var quoteCardAppearOpacity: Double = 1.0
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Initialization

    init() {
        // Initialize with a placeholder - will be replaced in .task with environment's context
        let placeholderContainer = ModelContainerHelper.createPlaceholderContainer()
        _viewModel = StateObject(wrappedValue: QuoteViewModel(
            modelContext: ModelContext(placeholderContainer)
        ))
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Liquid glass background
            backgroundGradient

            RunicAtmosphere(script: viewModel.state.currentScript)
                .ignoresSafeArea()

            // Content
            if viewModel.state.isLoading {
                loadingView
            } else if let error = viewModel.state.errorMessage {
                errorView(error)
            } else {
                quoteContentView
            }

            // Coach marks overlay
            if showCoachMarks {
                CoachMarksView {
                    hasCompletedFeatureTour = true
                    showCoachMarks = false
                }
            }
        }
        .task {
            guard !didInitialize else { return }
            didInitialize = true
            viewModel.configureIfNeeded(modelContext: modelContext)
            viewModel.onAppear()
        }
        .onChange(of: viewModel.state.isLoading) { _, isLoading in
            if !isLoading && !hasCompletedFeatureTour && didInitialize {
                showCoachMarks = true
            }
        }
        .onChange(of: viewModel.state.currentScript) { _, _ in
            startScriptMorphTransition()
        }
        .onReceive(NotificationCenter.default.publisher(for: .preferencesDidChange)) { _ in
            viewModel.onPreferencesChanged()
        }
        .onReceive(NotificationCenter.default.publisher(for: .switchToQuoteTab)) { notification in
            let scriptRaw = notification.userInfo?["script"] as? String
            let modeRaw = notification.userInfo?["mode"] as? String
            viewModel.onOpenQuoteDeepLink(scriptRaw: scriptRaw, modeRaw: modeRaw)
        }
        .onReceive(NotificationCenter.default.publisher(for: .loadNextQuote)) { _ in
            Haptics.trigger(.newQuote)
            viewModel.onNextQuoteTapped()
        }
        .onDisappear {
            NotificationCenter.default.post(
                name: .quoteTabBarVisibilityChanged,
                object: nil,
                userInfo: ["hidden": false]
            )
            scriptMorphTask?.cancel()
            scriptMorphTask = nil
        }
        .navigationTitle("Runic Quotes")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar { quoteToolbar }
        .searchable(text: $searchQuery, prompt: "Search quotes or authors")
        .searchSuggestions {
            ForEach(searchResults) { result in
                Button {
                    viewModel.showQuote(withID: result.id)
                    searchQuery = ""
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.latinText)
                            .lineLimit(1)
                        Text("— \(result.author)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onSubmit(of: .search) {
            if let firstResult = searchResults.first {
                viewModel.showQuote(withID: firstResult.id)
                searchQuery = ""
            }
        }
        .sheet(isPresented: $showShareView) {
            NavigationStack {
                ShareQuoteView(
                    runicText: viewModel.state.runicText,
                    latinText: viewModel.state.latinText,
                    author: viewModel.state.author,
                    script: viewModel.state.currentScript,
                    font: viewModel.state.currentFont
                )
            }
        }
        .sheet(isPresented: $showCreateQuote) {
            NavigationStack {
                CreateEditQuoteView(mode: .create) { _ in
                    viewModel.onAppear()
                }
            }
        }
        .sheet(isPresented: $showActionsSheet) {
            QuoteActionsSheet(isSaved: viewModel.state.isCurrentQuoteSaved) { action in
                handleQuoteAction(action)
            }
        }
        .sheet(isPresented: $showEditQuote) {
            if let record = viewModel.currentQuoteRecord() {
                NavigationStack {
                    CreateEditQuoteView(mode: .edit(record)) { _ in
                        viewModel.onAppear()
                    }
                }
            }
        }
        .alert("Delete Quote?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteCurrentQuote()
            }
        } message: {
            Text("This will move the quote to your archive. You can restore it later from Settings > Archive.")
        }
    }

    private var palette: AppThemePalette {
        .adaptive(for: colorScheme)
    }

    private var decorativeGlyph: String {
        switch viewModel.state.currentScript {
        case .elder: return "\u{16A0}"
        case .younger: return "\u{16A2}"
        case .cirth: return "\u{16CB}"
        }
    }

    private var searchResults: [QuoteSearchResult] {
        viewModel.searchResults(for: searchQuery)
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: palette.appBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            ZStack {
                Circle()
                    .fill(palette.accent.opacity(0.04))
                    .frame(width: 240, height: 240)
                    .blur(radius: 32)
                    .offset(x: 120, y: -220)

                Circle()
                    .fill(palette.accent.opacity(0.03))
                    .frame(width: 280, height: 280)
                    .blur(radius: 44)
                    .offset(x: -140, y: 260)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ProgressView()
                .tint(palette.accent)
                .scaleEffect(1.5)
                .accessibilityLabel("Loading")
                .accessibilityIdentifier("quote_loading_indicator")

            Text("Loading quote...")
                .font(.caption)
                .foregroundStyle(palette.textTertiary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading quote")
        .accessibilityIdentifier("quote_loading_view")
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        GlassCard(intensity: .medium) {
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(palette.error.opacity(0.8))
                    .accessibilityLabel("Error")

                Text("Error")
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                Text(message)
                    .font(.body)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)

                GlassButton.primary("Try Again", icon: "arrow.clockwise") {
                    viewModel.refresh()
                }
                .accessibilityLabel("Retry loading quote")
                .accessibilityHint("Double tap to try loading the quote again")
                .accessibilityIdentifier("quote_retry_button")
            }
            .padding(DesignTokens.Spacing.md)
        }
        .padding(DesignTokens.Spacing.md)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("quote_error_view")
    }

    // MARK: - Quote Content

    private var quoteContentView: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xxl) {
                Spacer()
                    .frame(height: DesignTokens.Spacing.lg)

                scriptPicker

                // Collection cover cards
                collectionCarousel

                if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    searchResultsSection
                }

                // Quote card
                quoteCard

                Spacer()
                    .frame(height: DesignTokens.Spacing.lg)
            }
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: QuoteScrollOffsetKey.self,
                        value: proxy.frame(in: .named("quote_scroll")).minY
                    )
                }
            )
        }
        .coordinateSpace(name: "quote_scroll")
        .onPreferenceChange(QuoteScrollOffsetKey.self) { offset in
            handleScrollOffsetChange(offset)
        }
    }

    private var collectionCarousel: some View {
        CollectionCoverCarousel(
            covers: viewModel.state.collectionCovers,
            selectedCollection: viewModel.state.currentCollection,
            script: viewModel.state.currentScript,
            font: viewModel.state.currentFont,
            palette: palette
        ) { collection in
            guard collection != viewModel.state.currentCollection else { return }
            Haptics.trigger(.scriptSwitch)
            viewModel.onCollectionChanged(collection)
        }
        .accessibilityIdentifier("quote_collection_carousel")
    }

    private var scriptPicker: some View {
        Picker(
            "Runic Script",
            selection: Binding(
                get: { viewModel.state.currentScript },
                set: { newScript in
                    Haptics.trigger(.scriptSwitch)
                    viewModel.onScriptChanged(newScript)
                }
            )
        ) {
            ForEach(RunicScript.allCases) { script in
                Text(script.displayName).tag(script)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .accessibilityLabel("Runic script selector")
        .accessibilityValue(viewModel.state.currentScript.rawValue)
        .accessibilityHint("Select which runic script to display")
        .accessibilityIdentifier("quote_script_selector")
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Search Results")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            if searchResults.isEmpty {
                Text("No matches found in \(viewModel.state.currentCollection.displayName).")
                    .font(.caption)
                    .foregroundStyle(palette.textTertiary)
            } else {
                VStack(spacing: DesignTokens.Spacing.xs) {
                    ForEach(searchResults.prefix(4)) { result in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.showQuote(withID: result.id)
                            }
                        } label: {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                                    Text(result.latinText)
                                        .font(.subheadline)
                                        .foregroundStyle(palette.textPrimary)
                                        .lineLimit(1)

                                    Text("— \(result.author)")
                                        .font(.caption)
                                        .foregroundStyle(palette.textTertiary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.left")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(palette.textSecondary)
                            }
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    // MARK: - Quote Card

    private var quoteCard: some View {
        GlassCard(intensity: .strong) {
            VStack(spacing: 0) {
                // Hero zone: dominant runic text
                Text(viewModel.state.runicText)
                    .runicTextStyle(
                        script: viewModel.state.currentScript,
                        font: viewModel.state.currentFont,
                        style: .title,
                        minSize: 28,
                        maxSize: 56
                    )
                    .foregroundStyle(palette.runeText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                    .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.top, DesignTokens.Spacing.xs)
                    .padding(.bottom, DesignTokens.Spacing.lg)
                    .opacity(isScriptMorphing ? 0.2 : 1.0)
                    .blur(radius: isScriptMorphing ? 7 : 0)
                    .scaleEffect(isScriptMorphing ? 0.98 : 1.0)
                    .contentTransition(.opacity)
                    .accessibilityLabel("Runic text")
                    .accessibilityValue(viewModel.state.runicText)
                    .accessibilityHint("The quote displayed in \(viewModel.state.currentScript.rawValue)")

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                palette.separator.opacity(0.5),
                                palette.separator.opacity(0.7),
                                palette.separator.opacity(0.5),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1.5)
                    .padding(.horizontal, DesignTokens.Spacing.xs)
                    .accessibilityHidden(true)

                // Secondary zone: translation
                Text(viewModel.state.latinText)
                    .font(.body)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.top, DesignTokens.Spacing.md)
                    .padding(.bottom, DesignTokens.Spacing.sm)
                    .opacity(isScriptMorphing ? 0.65 : 1.0)
                    .contentTransition(.opacity)
                    .accessibilityLabel("Quote")
                    .accessibilityValue(viewModel.state.latinText)
                    .accessibilityIdentifier("quoteText")

                Spacer(minLength: 8)

                // Fixed footer zone: author
                HStack {
                    Text("— \(viewModel.state.author)")
                        .font(.callout)
                        .foregroundStyle(palette.textTertiary)
                        .italic()
                        .accessibilityLabel("Author")
                        .accessibilityValue(viewModel.state.author)
                        .accessibilityIdentifier("authorText")

                    Spacer()
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .background(palette.surface)
            }
            .frame(maxWidth: .infinity, minHeight: 360, alignment: .top)
            .overlay(alignment: .topTrailing) {
                Text(decorativeGlyph)
                    .font(.system(size: 60))
                    .foregroundStyle(palette.textPrimary)
                    .opacity(0.03)
                    .rotationEffect(.degrees(-12))
                    .padding(.top, DesignTokens.Spacing.sm)
                    .padding(.trailing, DesignTokens.Spacing.md)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .scaleEffect(quoteCardAppearScale)
        .opacity(quoteCardAppearOpacity)
        .onChange(of: viewModel.state.latinText) { _, _ in
            guard !reduceMotion else { return }
            quoteCardAppearScale = 0.97
            quoteCardAppearOpacity = 0.6
            withAnimation(AnimationPresets.cardAppear) {
                quoteCardAppearScale = 1.0
                quoteCardAppearOpacity = 1.0
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("quote_card")
        .onLongPressGesture {
            Haptics.trigger(.saveOrShare)
            showActionsSheet = true
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var quoteToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Text(viewModel.state.currentCollection.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.textTertiary)
                .padding(.horizontal, DesignTokens.Spacing.xs)
                .padding(.vertical, DesignTokens.Spacing.xxs + 1)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
        }

        ToolbarItemGroup(placement: .primaryAction) {
            NavigationLink {
                NotificationCenterView()
            } label: {
                Image(systemName: "bell")
                    .symbolRenderingMode(.monochrome)
            }
            .accessibilityLabel("Notifications")
            .accessibilityIdentifier("quote_notifications_button")

            Button {
                showCreateQuote = true
            } label: {
                Image(systemName: "plus")
                    .symbolRenderingMode(.monochrome)
            }
            .accessibilityLabel("Create quote")
            .accessibilityIdentifier("quote_create_button")

            Button {
                Haptics.trigger(.newQuote)
                viewModel.onNextQuoteTapped()
            } label: {
                Image(systemName: "sparkles")
                    .symbolRenderingMode(.monochrome)
            }
            .accessibilityLabel("New quote")
            .accessibilityHint("Double tap to load a new random quote")
            .accessibilityIdentifier("quote_next_button")

            Button {
                Haptics.trigger(.saveOrShare)
                viewModel.onToggleSaveTapped()
            } label: {
                Image(systemName: viewModel.state.isCurrentQuoteSaved ? "bookmark.fill" : "bookmark")
                    .symbolRenderingMode(.monochrome)
                    .symbolEffect(.bounce, value: viewModel.state.isCurrentQuoteSaved)
            }
            .accessibilityLabel(viewModel.state.isCurrentQuoteSaved ? "Unsave quote" : "Save quote")
            .accessibilityIdentifier("quote_save_button")

            Button {
                Haptics.trigger(.saveOrShare)
                showActionsSheet = true
            } label: {
                Image(systemName: "ellipsis.circle")
                    .symbolRenderingMode(.monochrome)
            }
            .accessibilityLabel("More actions")
            .accessibilityIdentifier("quote_actions_button")
        }
    }

    // MARK: - Script Morph Animation

    private func startScriptMorphTransition() {
        scriptMorphTask?.cancel()
        scriptMorphTask = Task { @MainActor in
            withAnimation(.easeOut(duration: 0.08)) {
                isScriptMorphing = true
            }

            try? await Task.sleep(nanoseconds: 90_000_000)
            guard !Task.isCancelled else { return }

            withAnimation(.easeInOut(duration: 0.22)) {
                isScriptMorphing = false
            }
        }
    }

    private func handleScrollOffsetChange(_ offset: CGFloat) {
        let delta = offset - lastKnownScrollOffset
        guard abs(delta) > 14 else { return }

        let shouldHideTabBar = delta < 0 && offset < -22
        NotificationCenter.default.post(
            name: .quoteTabBarVisibilityChanged,
            object: nil,
            userInfo: ["hidden": shouldHideTabBar]
        )
        lastKnownScrollOffset = offset
    }

    private func copyCurrentQuote() {
        let payload = "\(viewModel.state.latinText)\n— \(viewModel.state.author)"

#if canImport(UIKit)
        UIPasteboard.general.string = payload
#elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(payload, forType: .string)
#endif
    }

    // MARK: - Quote Actions

    private func handleQuoteAction(_ action: QuoteAction) {
        switch action {
        case .share:
            showShareView = true
        case .addToFavorites, .removeFromFavorites:
            Haptics.trigger(.saveOrShare)
            viewModel.onToggleSaveTapped()
        case .addToCollection:
            // Currently quotes belong to one collection set at creation.
            // Open edit flow so the user can change the collection.
            showEditQuote = true
        case .copyText:
            copyCurrentQuote()
        case .edit:
            showEditQuote = true
        case .hide:
            viewModel.hideCurrentQuote()
        case .delete:
            showDeleteConfirmation = true
        }
    }

}

private struct QuoteScrollOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview {
    QuoteView()
        .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}

#Preview("With Sample Data") {
    let container = ModelContainerHelper.createPlaceholderContainer()

    // Add sample quote
    let quote = Quote(
        textLatin: "Not all those who wander are lost.",
        author: "J.R.R. Tolkien"
    )
    quote.runicElder = "ᚾᛟᛏ ᚨᛚᛚ ᚦᛟᛋᛖ ᚹᚺᛟ ᚹᚨᚾᛞᛖᚱ ᚨᚱᛖ ᛚᛟᛋᛏ"
    container.mainContext.insert(quote)

    return QuoteView()
        .modelContainer(container)
}
