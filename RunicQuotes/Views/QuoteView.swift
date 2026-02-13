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
    @Environment(\.modelContext) private var modelContext

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
            scriptMorphTask?.cancel()
            scriptMorphTask = nil
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

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: themePalette.appBackgroundGradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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

                GlassButton.primary("Try Again", icon: "arrow.clockwise") {
                    viewModel.refresh()
                }
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

                // Script selector
                GlassScriptSelector(
                    selectedScript: Binding(
                        get: { viewModel.state.currentScript },
                        set: { viewModel.onScriptChanged($0) }
                    )
                )
                .padding(.horizontal)
                .accessibilityLabel("Runic script selector")
                .accessibilityValue(viewModel.state.currentScript.rawValue)
                .accessibilityHint("Select which runic script to display")
                .accessibilityIdentifier("quote_script_selector")

                // Quote card
                quoteCard

                // Action buttons
                actionButtons

                Spacer()
            }
        }
    }

    // MARK: - Quote Card

    private var quoteCard: some View {
        GlassCard(
            opacity: .medium,
            blur: .regularMaterial
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

                Divider()
                    .background(
                        LinearGradient(
                            colors: [
                                .clear,
                                themePalette.divider,
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
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
        }
        .padding(.horizontal)
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

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Primary action
            GlassButton.primary("New Quote", icon: "sparkles", hapticTier: .newQuote) {
                viewModel.onNextQuoteTapped()
            }
            .accessibilityLabel("New quote")
            .accessibilityHint("Double tap to load a new random quote")
            .accessibilityIdentifier("quote_next_button")

            // Contextual secondary action
            GlassButton.secondary(
                viewModel.state.isCurrentQuoteSaved ? "Unsave" : "Save",
                icon: viewModel.state.isCurrentQuoteSaved ? "bookmark.slash" : "bookmark",
                hapticTier: .saveOrShare
            ) {
                viewModel.onToggleSaveTapped()
            }
            .accessibilityLabel(viewModel.state.isCurrentQuoteSaved ? "Unsave quote" : "Save quote")
            .accessibilityHint("Double tap to toggle saved status for this quote")
            .accessibilityIdentifier("quote_save_button")
        }
        .padding(.horizontal)
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
