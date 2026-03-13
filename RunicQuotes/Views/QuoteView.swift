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
    @State private var showTranslationView = false
    @State private var showActionsSheet = false
    @State private var showDeleteConfirmation = false
    @State private var editingQuoteRecord: QuoteRecord?
    @State private var showCoachMarks = false
    @AppStorage(AppConstants.featureTourCompletedKey) private var hasCompletedFeatureTour = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @EnvironmentObject private var homeAccessoryController: HomeAccessoryController
    private let createEditQuoteViewBuilder: CreateEditQuoteViewBuilder
    private let translationViewBuilder: TranslationViewBuilder

    // MARK: - Initialization

    init(
        viewModel: QuoteViewModel,
        createEditQuoteViewBuilder: CreateEditQuoteViewBuilder,
        translationViewBuilder: TranslationViewBuilder
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.createEditQuoteViewBuilder = createEditQuoteViewBuilder
        self.translationViewBuilder = translationViewBuilder
    }

    // MARK: - Body

    var body: some View {
        presentedContent
    }

    private var lifecycleAwareContent: some View {
        rootContent
            .task {
                guard !didInitialize else { return }
                didInitialize = true
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
            .onReceive(NotificationCenter.default.publisher(for: .translationCacheUpdated)) { notification in
                let quoteID = notification.userInfo?["quoteID"] as? UUID
                viewModel.onTranslationCacheUpdated(for: quoteID)
            }
            .onChange(of: viewModel.state.currentCollection) { _, _ in
                syncHomeAccessory()
            }
            .onChange(of: viewModel.state.currentScript) { _, _ in
                syncHomeAccessory()
            }
            .onChange(of: viewModel.state.latinText) { _, _ in
                syncHomeAccessory()
            }
    }

    private var chromeContent: some View {
        lifecycleAwareContent
            .onDisappear {
                scriptMorphTask?.cancel()
                scriptMorphTask = nil
                homeAccessoryController.hide()
            }
            .navigationTitle("Home")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                QuoteToolbar(
                    currentCollection: viewModel.state.currentCollection,
                    palette: palette,
                    createQuote: {
                        showCreateQuote = true
                    },
                    openTranslation: {
                        showTranslationView = true
                    }
                )
            }
    }

    private var presentedContent: some View {
        chromeContent
            .sheet(isPresented: $showShareView) {
                NavigationStack {
                    ShareQuoteView(
                        runicText: viewModel.state.runicText,
                        latinText: viewModel.state.latinText,
                        author: viewModel.state.author,
                        script: viewModel.state.currentScript,
                        font: viewModel.state.currentFont,
                        presentationSource: viewModel.state.runicPresentationSource,
                        evidenceTier: viewModel.state.runicEvidenceTier,
                        primarySourceLabel: viewModel.state.runicPrimarySourceLabel
                    )
                }
            }
            .sheet(isPresented: $showCreateQuote) {
                NavigationStack {
                    createEditQuoteViewBuilder.makeView(mode: .create, onSaved: { _ in
                        viewModel.onAppear()
                    })
                }
            }
            .sheet(isPresented: $showTranslationView) {
                NavigationStack {
                    translationViewBuilder.makeView()
                }
            }
            .confirmationDialog(
                "Current passage",
                isPresented: $showActionsSheet,
                titleVisibility: .visible
            ) {
                ForEach(availableQuoteActions) { action in
                    Button(action.title, role: action.isDestructive ? .destructive : nil) {
                        handleQuoteAction(action)
                    }
                }
            } message: {
                Text("Choose how this quote should be handled.")
            }
            .sheet(item: $editingQuoteRecord) { record in
                NavigationStack {
                    createEditQuoteViewBuilder.makeView(mode: .edit(record), onSaved: { _ in
                        viewModel.onAppear()
                    })
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
            .task(id: viewModel.state.currentQuoteID) {
                syncHomeAccessory()
            }
    }

    @ViewBuilder
    private var rootContent: some View {
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
                .opacity(0.08)
                .allowsHitTesting(false)

            // Coach marks overlay
            if showCoachMarks {
                CoachMarksView {
                    hasCompletedFeatureTour = true
                    showCoachMarks = false
                }
            }
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

    private var availableQuoteActions: [QuoteAction] {
        [
            .share,
            viewModel.state.isCurrentQuoteSaved ? .removeFromFavorites : .addToFavorites,
            .addToCollection,
            .copyText,
            .edit,
            .hide,
            .delete
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
                    viewModel.state.currentCollection.displayName,
                    viewModel.state.currentScript.displayName,
                    viewModel.state.currentWidgetMode.displayName
                ],
                palette: palette
            )

            homeChrome

            QuoteCardSectionView(
                runicText: viewModel.state.runicText,
                presentationSource: viewModel.state.runicPresentationSource,
                evidenceTier: viewModel.state.runicEvidenceTier,
                primarySourceLabel: viewModel.state.runicPrimarySourceLabel,
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
        }
    }

    private var homeChrome: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            QuoteScriptPickerView(
                palette: palette,
                selectedScript: viewModel.state.currentScript
            ) { newScript in
                Haptics.trigger(.scriptSwitch)
                viewModel.onScriptChanged(newScript)
            }

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

            Button {
                NotificationCenter.default.post(
                    name: .switchToTab,
                    object: nil,
                    userInfo: ["tab": AppTab.search]
                )
            } label: {
                LiquidCard(
                    palette: palette,
                    role: .chrome,
                    cornerRadius: DesignTokens.CornerRadius.xl,
                    shadowRadius: DesignTokens.Elevation.chrome,
                    contentPadding: DesignTokens.Spacing.md,
                    interactive: true
                ) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(palette.subtleAccentText)

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                            Text("Search the library")
                                .font(DesignTokens.Typography.bodyLarge)
                                .foregroundStyle(palette.textPrimary)

                            Text("Move into the dedicated Search tab for authors, fragments, and collections.")
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(palette.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(palette.subtleAccentText)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    private func syncHomeAccessory() {
        guard didInitialize else { return }
        homeAccessoryController.update(
            collection: viewModel.state.currentCollection,
            script: viewModel.state.currentScript,
            caption: viewModel.state.author.isEmpty ? "Continue reading" : viewModel.state.author
        )
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

// MARK: - Preview

private enum QuoteViewPreviewFactory {
    @MainActor
    static func sampleContainer() -> ModelContainer {
        let container = ModelContainerHelper.createPlaceholderContainer()
        let quote = Quote(
            textLatin: "Not all those who wander are lost.",
            author: "J.R.R. Tolkien"
        )
        quote.runicElder = "ᚾᛟᛏ ᚨᛚᛚ ᚦᛟᛋᛖ ᚹᚺᛟ ᚹᚨᚾᛞᛖᚱ ᚨᚱᛖ ᛚᛟᛋᛏ"
        container.mainContext.insert(quote)
        return container
    }
}

#Preview {
    QuoteView(
        viewModel: QuoteViewModel.preview(),
        createEditQuoteViewBuilder: CreateEditQuoteViewBuilder { mode, onSaved in
            CreateEditQuoteView(
                viewModel: CreateEditQuoteViewModel.preview(mode: mode),
                mode: mode,
                onSaved: onSaved
            )
        },
        translationViewBuilder: TranslationViewBuilder {
            TranslationView(viewModel: TranslationViewModel.preview())
        }
    )
        .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}

#Preview("With Sample Data") {
    QuoteView(
        viewModel: QuoteViewModel.preview(),
        createEditQuoteViewBuilder: CreateEditQuoteViewBuilder { mode, onSaved in
            CreateEditQuoteView(
                viewModel: CreateEditQuoteViewModel.preview(mode: mode),
                mode: mode,
                onSaved: onSaved
            )
        },
        translationViewBuilder: TranslationViewBuilder {
            TranslationView(viewModel: TranslationViewModel.preview())
        }
    )
    .modelContainer(QuoteViewPreviewFactory.sampleContainer())
}
// swiftlint:enable type_body_length
