//
//  SavedView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI

/// Displays bookmarked/favorited quotes.
struct SavedView: View {
    @StateObject private var viewModel: SavedQuotesViewModel
    @State private var didInitialize = false
    @State private var feedbackTone: FeedbackBanner.Tone?
    @State private var feedbackTitle = ""
    @State private var feedbackMessage = ""
    @State private var feedbackTask: Task<Void, Never>?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme

    private var palette: AppThemePalette {
        .themed(runicTheme, for: colorScheme)
    }

    // MARK: - Initialization

    init(viewModel: SavedQuotesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        LiquidListScaffold(palette: palette) {
            Section {
                HeroHeader(
                    eyebrow: "Saved",
                    title: "Personal Library",
                    subtitle: "The lines you chose to keep, arranged for easy return.",
                    meta: ["\(viewModel.savedCount) saved passages"],
                    palette: palette
                )
                .listRowInsets(EdgeInsets(
                    top: DesignTokens.Spacing.lg,
                    leading: DesignTokens.Spacing.md,
                    bottom: DesignTokens.Spacing.md,
                    trailing: DesignTokens.Spacing.md
                ))
            }

            if let tone = feedbackTone {
                Section {
                    FeedbackBanner(
                        palette: palette,
                        tone: tone,
                        title: feedbackTitle,
                        message: feedbackMessage
                    )
                }
            }

            if let error = viewModel.state.errorMessage {
                Section {
                    FeedbackBanner(
                        palette: palette,
                        tone: .error,
                        title: "Library unavailable",
                        message: error
                    )
                }
            }

            if viewModel.state.isLoading {
                Section {
                    InsetCard(palette: palette) {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ProgressView()
                                .tint(palette.accent)
                            Text("Loading saved passages...")
                                .font(DesignTokens.Typography.callout)
                                .foregroundStyle(palette.textSecondary)
                        }
                    }
                }
            } else if viewModel.state.savedQuotes.isEmpty {
                Section {
                    emptyState
                }
            } else {
                Section {
                    savedList
                }
            }
        }
        .navigationTitle("Saved")
        .task {
            guard !didInitialize else { return }
            didInitialize = true
            viewModel.onAppear()
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        EditorialEmptyState(
            palette: palette,
            icon: "bookmark",
            eyebrow: "Library",
            title: "No saved passages yet",
            message: "When a line matters, save it from Home and it will wait here."
        )
    }

    // MARK: - Saved List

    @ViewBuilder
    private var savedList: some View {
        ForEach(viewModel.state.savedQuotes, id: \.id) { quote in
            savedQuoteCard(quote)
        }
    }

    // MARK: - Quote Card

    @ViewBuilder
    private func savedQuoteCard(_ quote: QuoteRecord) -> some View {
        QuoteCardView(
            runicSnippet: quote.runicElder ?? "",
            quoteText: quote.textLatin,
            author: quote.author,
            badge: {
                collectionBadge(for: quote)
            },
            actions: {
                inlineActions(for: quote)
            }
        )
        .contextMenu {
            savedContextMenu(for: quote)
        }
    }

    private func collectionBadge(for quote: QuoteRecord) -> some View {
        Text(quote.collection.displayName)
            .font(DesignTokens.Typography.metadata)
            .foregroundStyle(palette.accent)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background {
                Capsule()
                    .fill(palette.bannerBackground)
            }
    }

    private func inlineActions(for quote: QuoteRecord) -> some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Button {
                removeSavedQuote(quote)
            } label: {
                Label("Remove", systemImage: "bookmark.slash")
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(palette.accent)
            }
            .buttonStyle(.plain)

            Button {
                copySavedQuote(quote)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(DesignTokens.Typography.label)
                    .foregroundStyle(palette.textPrimary)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func savedContextMenu(for quote: QuoteRecord) -> some View {
        Button("Copy", systemImage: "doc.on.doc") {
            copySavedQuote(quote)
        }

        Button("Remove", systemImage: "bookmark.slash", role: .destructive) {
            removeSavedQuote(quote)
        }
    }

    private func copySavedQuote(_ quote: QuoteRecord) {
#if canImport(UIKit)
        UIPasteboard.general.string = viewModel.copyQuoteText(quote)
#endif
        showFeedback(
            tone: .success,
            title: "Copied",
            message: "The quote text is ready to paste."
        )
    }

    private func removeSavedQuote(_ quote: QuoteRecord) {
        viewModel.toggleSaved(quote.id)
        showFeedback(
            tone: .success,
            title: "Removed from saved",
            message: "The passage left your personal library."
        )
    }

    private func showFeedback(
        tone: FeedbackBanner.Tone,
        title: String,
        message: String
    ) {
        feedbackTask?.cancel()
        feedbackTone = tone
        feedbackTitle = title
        feedbackMessage = message

        feedbackTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            feedbackTone = nil
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SavedView(viewModel: SavedQuotesViewModel.preview())
    }
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
