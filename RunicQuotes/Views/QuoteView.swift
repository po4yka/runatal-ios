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

// swiftlint:disable type_body_length
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
    @State private var editingQuoteRecord: QuoteRecord?
    @State private var searchQuery = ""
    @State private var showCoachMarks = false
    @State private var lastKnownScrollOffset: CGFloat = 0
    @AppStorage(AppConstants.featureTourCompletedKey) private var hasCompletedFeatureTour = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme

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
            ScreenScaffold(
                palette: palette,
                scrollEnabled: !viewModel.state.isLoading && viewModel.state.errorMessage == nil
            ) {
                if viewModel.state.isLoading {
                    QuoteLoadingView(palette: palette)
                        .frame(maxWidth: .infinity, minHeight: 480, alignment: .center)
                } else if let error = viewModel.state.errorMessage {
                    QuoteErrorView(message: error, palette: palette) {
                        viewModel.refresh()
                    }
                    .frame(maxWidth: .infinity, minHeight: 480, alignment: .center)
                } else {
                    quoteContentView
                }
            }

            RunicAtmosphere(script: viewModel.state.currentScript)
                .ignoresSafeArea()
                .opacity(0.18)
                .allowsHitTesting(false)

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
        .navigationTitle("Home")
#if os(iOS)
        .navigationBarTitleDisplayMode(.automatic)
#endif
        .toolbar {
            QuoteToolbar(
                currentCollection: viewModel.state.currentCollection,
                palette: palette,
                createQuote: {
                    showCreateQuote = true
                }
            )
        }
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
        .sheet(item: $editingQuoteRecord) { record in
            NavigationStack {
                CreateEditQuoteView(mode: .edit(record)) { _ in
                    viewModel.onAppear()
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
        .themed(runicTheme, for: colorScheme)
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

    // MARK: - Quote Content

    private var quoteContentView: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            HeroHeader(
                eyebrow: "Home",
                title: "Today's Reading",
                subtitle: viewModel.state.currentCollection.heroLatinText,
                meta: [
                    viewModel.state.currentCollection.displayName,
                    viewModel.state.currentScript.displayName,
                    viewModel.state.currentWidgetMode.displayName
                ],
                palette: palette
            )

            QuoteScriptPickerView(
                palette: palette,
                selectedScript: viewModel.state.currentScript
            ) { newScript in
                Haptics.trigger(.scriptSwitch)
                viewModel.onScriptChanged(newScript)
            }

            collectionCarousel

            QuoteCardSectionView(
                runicText: viewModel.state.runicText,
                latinText: viewModel.state.latinText,
                author: viewModel.state.author,
                script: viewModel.state.currentScript,
                font: viewModel.state.currentFont,
                decorativeGlyph: decorativeGlyph,
                palette: palette,
                isScriptMorphing: isScriptMorphing,
                isSaved: viewModel.state.isCurrentQuoteSaved,
                onNextQuote: {
                    Haptics.trigger(.newQuote)
                    viewModel.onNextQuoteTapped()
                },
                onToggleSave: {
                    Haptics.trigger(.saveOrShare)
                    viewModel.onToggleSaveTapped()
                },
                onShowActions: {
                    Haptics.trigger(.saveOrShare)
                    showActionsSheet = true
                }
            )

            if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                QuoteSearchResultsSectionView(
                    currentCollection: viewModel.state.currentCollection,
                    results: searchResults,
                    palette: palette
                ) { result in
                    withAnimation(DesignTokens.Motion.emphasis) {
                        viewModel.showQuote(withID: result.id)
                    }
                }
            }
        }
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: QuoteScrollOffsetKey.self,
                    value: proxy.frame(in: .named("quote_scroll")).minY
                )
            }
        )
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

    // MARK: - Script Morph Animation

    private func startScriptMorphTransition() {
        scriptMorphTask?.cancel()
        scriptMorphTask = Task { @MainActor in
            withAnimation(.easeOut(duration: 0.08)) {
                isScriptMorphing = true
            }

            try? await Task.sleep(for: .milliseconds(90))
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
            editingQuoteRecord = viewModel.currentQuoteRecord()
        case .copyText:
            copyCurrentQuote()
        case .edit:
            editingQuoteRecord = viewModel.currentQuoteRecord()
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
// swiftlint:enable type_body_length
