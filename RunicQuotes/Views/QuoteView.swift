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
    @State private var isShareSheetPresented = false
    @State private var shareItems: [Any] = []
    @State private var searchQuery = ""
    @State private var lastKnownScrollOffset: CGFloat = 0
    @State private var quoteCardAppearScale: CGFloat = 1.0
    @State private var quoteCardAppearOpacity: Double = 1.0
    @Environment(\.modelContext) private var modelContext
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
        }
        .task {
            guard !didInitialize else { return }
            didInitialize = true
            viewModel.configureIfNeeded(modelContext: modelContext)
            viewModel.onAppear()
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
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
        .sheet(isPresented: $isShareSheetPresented) {
#if canImport(UIKit)
            ActivityViewController(activityItems: shareItems)
#else
            Text("Sharing is unavailable on this platform.")
                .padding()
#endif
        }
    }

    private var themePalette: AppThemePalette {
        viewModel.state.currentTheme.palette
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
            colors: themePalette.appBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 240, height: 240)
                    .blur(radius: 32)
                    .offset(x: 120, y: -220)

                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 280, height: 280)
                    .blur(radius: 44)
                    .offset(x: -140, y: 260)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(themePalette.accent)
                .scaleEffect(1.5)
                .accessibilityLabel("Loading")
                .accessibilityIdentifier("quote_loading_indicator")

            Text("Loading quote...")
                .font(.caption)
                .foregroundColor(themePalette.tertiaryText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading quote")
        .accessibilityIdentifier("quote_loading_view")
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        GlassCard {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red.opacity(0.8))
                    .accessibilityLabel("Error")

                Text("Error")
                    .font(.headline)
                    .foregroundColor(themePalette.primaryText)

                Text(message)
                    .font(.body)
                    .foregroundColor(themePalette.secondaryText)
                    .multilineTextAlignment(.center)

                Button {
                    viewModel.refresh()
                }
                label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption.weight(.semibold))
                        Text("Try Again")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(themePalette.primaryText.opacity(0.92))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .opacity(0.8)
                    )
                    .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Retry loading quote")
                .accessibilityHint("Double tap to try loading the quote again")
                .accessibilityIdentifier("quote_retry_button")
            }
            .padding()
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("quote_error_view")
    }

    // MARK: - Quote Content

    private var quoteContentView: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 20)

                scriptPicker

                // Collection cover cards
                collectionCarousel

                if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    searchResultsSection
                }

                // Quote card
                quoteCard

                Spacer()
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
            palette: themePalette
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
        .padding(.horizontal)
        .accessibilityLabel("Runic script selector")
        .accessibilityValue(viewModel.state.currentScript.rawValue)
        .accessibilityHint("Select which runic script to display")
        .accessibilityIdentifier("quote_script_selector")
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Search Results")
                .font(.headline)
                .foregroundColor(themePalette.primaryText)

            if searchResults.isEmpty {
                Text("No matches found in \(viewModel.state.currentCollection.displayName).")
                    .font(.caption)
                    .foregroundColor(themePalette.tertiaryText)
            } else {
                VStack(spacing: 8) {
                    ForEach(searchResults.prefix(4)) { result in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.showQuote(withID: result.id)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(result.latinText)
                                        .font(.subheadline)
                                        .foregroundColor(themePalette.primaryText)
                                        .lineLimit(1)

                                    Text("— \(result.author)")
                                        .font(.caption)
                                        .foregroundColor(themePalette.tertiaryText)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.left")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(themePalette.secondaryText)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Quote Card

    private var quoteCard: some View {
        GlassCard(
            opacity: .high,
            blur: .ultraThinMaterial
        ) {
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
                    .foregroundColor(themePalette.primaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(10)
                    .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
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
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.08),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1.5)
                    .padding(.horizontal, 8)
                    .accessibilityHidden(true)

                // Secondary zone: translation
                Text(viewModel.state.latinText)
                    .font(.body)
                    .foregroundColor(themePalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 14)
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
                        .foregroundColor(themePalette.tertiaryText)
                        .italic()
                        .accessibilityLabel("Author")
                        .accessibilityValue(viewModel.state.author)
                        .accessibilityIdentifier("authorText")

                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .background(themePalette.footerBackground)
            }
            .frame(maxWidth: .infinity, minHeight: 360, alignment: .top)
            .overlay(alignment: .topTrailing) {
                Text(decorativeGlyph)
                    .font(.system(size: 60))
                    .foregroundColor(themePalette.primaryText)
                    .opacity(0.03)
                    .rotationEffect(.degrees(-12))
                    .padding(.top, 12)
                    .padding(.trailing, 16)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }
        }
        .padding(.horizontal)
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
        .contextMenu {
            Button {
                copyCurrentQuote()
            } label: {
                Label("Copy Quote", systemImage: "doc.on.doc")
            }

            Button {
                shareCurrentQuoteAsImage()
            } label: {
                Label("Share Image", systemImage: "square.and.arrow.up")
            }

            Button {
                Haptics.trigger(.saveOrShare)
                viewModel.onToggleSaveTapped()
            } label: {
                Label(
                    viewModel.state.isCurrentQuoteSaved ? "Unsave Quote" : "Save Quote",
                    systemImage: viewModel.state.isCurrentQuoteSaved ? "bookmark.slash" : "bookmark"
                )
            }

            Button {
                NotificationCenter.default.post(name: .switchToSettingsTab, object: nil)
            } label: {
                Label("Open Settings", systemImage: "gearshape")
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var quoteToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Text(viewModel.state.currentCollection.displayName)
                .font(.caption.weight(.semibold))
                .foregroundColor(themePalette.tertiaryText)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
        }

        ToolbarItemGroup(placement: .primaryAction) {
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

            Menu {
                Button {
                    copyCurrentQuote()
                } label: {
                    Label("Copy Quote", systemImage: "doc.on.doc")
                }

                Button {
                    shareCurrentQuoteAsImage()
                } label: {
                    Label("Share Image", systemImage: "square.and.arrow.up")
                }

                Button {
                    NotificationCenter.default.post(name: .switchToSettingsTab, object: nil)
                } label: {
                    Label("Open Settings", systemImage: "gearshape")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .symbolRenderingMode(.monochrome)
            }
            .accessibilityLabel("More actions")
        }
    }

    // MARK: - Bottom Accessory

    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            Button {
                Haptics.trigger(.newQuote)
                viewModel.onNextQuoteTapped()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.semibold))
                    Text("New Quote")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(themePalette.primaryText.opacity(0.92))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(0.8)
                )
                .shadow(color: .black.opacity(0.22), radius: 6, x: 0, y: 3)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("New quote")
            .accessibilityHint("Double tap to load a new random quote")
            .accessibilityIdentifier("quote_next_button")

            Button {
                Haptics.trigger(.saveOrShare)
                viewModel.onToggleSaveTapped()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.state.isCurrentQuoteSaved ? "bookmark.slash" : "bookmark")
                        .font(.caption.weight(.semibold))
                    Text(viewModel.state.isCurrentQuoteSaved ? "Unsave" : "Save")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(themePalette.primaryText.opacity(0.92))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(viewModel.state.isCurrentQuoteSaved ? "Unsave quote" : "Save quote")
            .accessibilityIdentifier("quote_bottom_save_button")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.22), radius: 8, x: 0, y: -2)
        .padding(.horizontal)
        .padding(.bottom, 6)
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

    @MainActor
    private func shareCurrentQuoteAsImage() {
#if canImport(UIKit)
        Haptics.trigger(.saveOrShare)

        let renderer = ImageRenderer(content: shareSnapshotView)
        renderer.scale = UIScreen.main.scale

        if let image = renderer.uiImage {
            shareItems = [image]
        } else {
            shareItems = ["\(viewModel.state.latinText)\n— \(viewModel.state.author)"]
        }

        isShareSheetPresented = true
#endif
    }

    private var shareSnapshotView: some View {
        VStack(spacing: 18) {
            Text(viewModel.state.runicText)
                .runicTextStyle(
                    script: viewModel.state.currentScript,
                    font: viewModel.state.currentFont,
                    style: .title,
                    minSize: 24,
                    maxSize: 48
                )
                .foregroundColor(themePalette.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Divider()
                .overlay(themePalette.divider)

            Text(viewModel.state.latinText)
                .font(.title3)
                .foregroundColor(themePalette.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text("— \(viewModel.state.author)")
                .font(.headline)
                .foregroundColor(themePalette.tertiaryText)
                .italic()
                .padding(.bottom, 8)
        }
        .padding(.vertical, 28)
        .frame(width: 1000)
        .background(
            LinearGradient(
                colors: themePalette.appBackgroundGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#if canImport(UIKit)
private struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

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
