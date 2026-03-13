//
//  SavedView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI
import SwiftData

/// Displays bookmarked/favorited quotes.
struct SavedView: View {
    @StateObject private var viewModel: SavedQuotesViewModel
    @State private var didInitialize = false
    @State private var feedbackTone: FeedbackBanner.Tone?
    @State private var feedbackTitle = ""
    @State private var feedbackMessage = ""
    @State private var feedbackTask: Task<Void, Never>?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme

    private var palette: AppThemePalette {
        .themed(runicTheme, for: colorScheme)
    }

    // MARK: - Initialization

    init() {
        _viewModel = StateObject(wrappedValue: SavedQuotesViewModel(
            modelContext: ModelContext(
                ModelContainerHelper.createPlaceholderContainer()
            )
        ))
    }

    // MARK: - Body

    var body: some View {
        ScreenScaffold(palette: palette) {
            HeroHeader(
                eyebrow: "Saved",
                title: "Personal Library",
                subtitle: "The lines you chose to keep, arranged for easy return.",
                meta: ["\(viewModel.savedCount) saved passages"],
                palette: palette
            )

            if let tone = feedbackTone {
                FeedbackBanner(
                    palette: palette,
                    tone: tone,
                    title: feedbackTitle,
                    message: feedbackMessage
                )
            }

            if let error = viewModel.state.errorMessage {
                FeedbackBanner(
                    palette: palette,
                    tone: .error,
                    title: "Library unavailable",
                    message: error
                )
            }

            if viewModel.state.isLoading {
                InsetCard(palette: palette) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        ProgressView()
                            .tint(palette.accent)
                        Text("Loading saved passages...")
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(palette.textSecondary)
                    }
                }
            } else if viewModel.state.savedQuotes.isEmpty {
                emptyState
            } else {
                savedList
            }
        }
        .navigationTitle("Saved")
        .task {
            guard !didInitialize else { return }
            didInitialize = true
            viewModel.configureIfNeeded(modelContext: modelContext)
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
        LazyVStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(viewModel.state.savedQuotes, id: \.id) { quote in
                savedQuoteCard(quote)
            }
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
                Text(quote.collection.displayName)
                    .font(DesignTokens.Typography.metadata)
                    .foregroundStyle(palette.accent)
                    .padding(.horizontal, DesignTokens.Spacing.sm)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background {
                        Capsule()
                            .fill(palette.bannerBackground)
                    }
            },
            actions: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Button {
                        viewModel.toggleSaved(quote.id)
                        showFeedback(
                            tone: .success,
                            title: "Removed from saved",
                            message: "The passage left your personal library."
                        )
                    } label: {
                        Label("Remove", systemImage: "bookmark.slash")
                            .font(DesignTokens.Typography.label)
                            .foregroundStyle(palette.accent)
                    }
                    .buttonStyle(.plain)

                    Button {
#if canImport(UIKit)
                        UIPasteboard.general.string = viewModel.copyQuoteText(quote)
#endif
                        showFeedback(
                            tone: .success,
                            title: "Copied",
                            message: "The quote text is ready to paste."
                        )
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(DesignTokens.Typography.label)
                            .foregroundStyle(palette.textPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
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
        SavedView()
    }
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
