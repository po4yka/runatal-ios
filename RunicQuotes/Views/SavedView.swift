//
//  SavedView.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
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
        .themed(self.runicTheme, for: self.colorScheme)
    }

    // MARK: - Initialization

    init(viewModel: SavedQuotesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Body

    var body: some View {
        LiquidListScaffold(palette: self.palette) {
            Section {
                HeroHeader(
                    eyebrow: "Saved",
                    title: "Personal Library",
                    subtitle: "The lines you chose to keep, arranged for easy return.",
                    meta: ["\(self.viewModel.savedCount) saved passages"],
                    palette: self.palette,
                )
                .listRowInsets(EdgeInsets(
                    top: DesignTokens.Spacing.lg,
                    leading: DesignTokens.Spacing.md,
                    bottom: DesignTokens.Spacing.md,
                    trailing: DesignTokens.Spacing.md,
                ))
            }

            if let tone = feedbackTone {
                Section {
                    FeedbackBanner(
                        palette: self.palette,
                        tone: tone,
                        title: self.feedbackTitle,
                        message: self.feedbackMessage,
                    )
                }
            }

            if let error = viewModel.state.errorMessage {
                Section {
                    FeedbackBanner(
                        palette: self.palette,
                        tone: .error,
                        title: "Library unavailable",
                        message: error,
                    )
                }
            }

            if self.viewModel.state.isLoading {
                Section {
                    InsetCard(palette: self.palette) {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ProgressView()
                                .tint(self.palette.accent)
                            Text("Loading saved passages...")
                                .font(DesignTokens.Typography.callout)
                                .foregroundStyle(self.palette.textSecondary)
                        }
                    }
                }
            } else if self.viewModel.state.savedQuotes.isEmpty {
                Section {
                    self.emptyState
                }
            } else {
                Section {
                    self.savedList
                }
            }
        }
        .navigationTitle("Saved")
        .task {
            guard !self.didInitialize else { return }
            self.didInitialize = true
            self.viewModel.onAppear()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EditorialEmptyState(
            palette: self.palette,
            icon: "bookmark",
            eyebrow: "Library",
            title: "No saved passages yet",
            message: "When a line matters, save it from Home and it will wait here.",
        )
    }

    // MARK: - Saved List

    private var savedList: some View {
        ForEach(self.viewModel.state.savedQuotes, id: \.id) { quote in
            self.savedQuoteRow(quote)
        }
    }

    // MARK: - Quote Row

    private func savedQuoteRow(_ quote: QuoteRecord) -> some View {
        QuoteListRow(
            palette: self.palette,
            runicSnippet: quote.runicElder ?? "",
            quoteText: quote.textLatin,
            author: quote.author,
            metadata: [],
            badge: {
                self.collectionBadge(for: quote)
            },
            footer: {
                Button {
                    self.removeSavedQuote(quote)
                } label: {
                    Label("Remove from saved", systemImage: "bookmark.slash")
                        .font(DesignTokens.Typography.controlLabel)
                        .foregroundStyle(self.palette.accent)
                }
                .buttonStyle(.plain)
            },
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                self.copySavedQuote(quote)
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }

            Button(role: .destructive) {
                self.removeSavedQuote(quote)
            } label: {
                Label("Remove", systemImage: "bookmark.slash")
            }
        }
        .contextMenu {
            self.savedContextMenu(for: quote)
        }
    }

    private func collectionBadge(for quote: QuoteRecord) -> some View {
        Text(quote.collection.displayName)
            .font(DesignTokens.Typography.listMeta)
            .foregroundStyle(self.palette.accent)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background {
                Capsule()
                    .fill(self.palette.bannerBackground)
            }
    }

    @ViewBuilder
    private func savedContextMenu(for quote: QuoteRecord) -> some View {
        Button("Copy", systemImage: "doc.on.doc") {
            self.copySavedQuote(quote)
        }

        Button("Remove", systemImage: "bookmark.slash", role: .destructive) {
            self.removeSavedQuote(quote)
        }
    }

    private func copySavedQuote(_ quote: QuoteRecord) {
        #if canImport(UIKit)
            UIPasteboard.general.string = self.viewModel.copyQuoteText(quote)
        #endif
        self.showFeedback(
            tone: .success,
            title: "Copied",
            message: "The quote text is ready to paste.",
        )
    }

    private func removeSavedQuote(_ quote: QuoteRecord) {
        self.viewModel.toggleSaved(quote.id)
        self.showFeedback(
            tone: .success,
            title: "Removed from saved",
            message: "The passage left your personal library.",
        )
    }

    private func showFeedback(
        tone: FeedbackBanner.Tone,
        title: String,
        message: String,
    ) {
        self.feedbackTask?.cancel()
        self.feedbackTone = tone
        self.feedbackTitle = title
        self.feedbackMessage = message

        self.feedbackTask = Task {
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            self.feedbackTone = nil
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
