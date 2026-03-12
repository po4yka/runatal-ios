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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        .adaptive(for: colorScheme)
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
        Group {
            if viewModel.state.isLoading {
                ProgressView()
            } else if viewModel.state.savedQuotes.isEmpty {
                emptyState
            } else {
                savedList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
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
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()

            Image(systemName: "bookmark")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(palette.textTertiary)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("No Saved Quotes")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(palette.textPrimary)

                Text("Quotes you save will appear here.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
    }

    // MARK: - Saved List

    @ViewBuilder
    private var savedList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                // Header: count
                Text("\(viewModel.savedCount) saved")
                    .font(.subheadline)
                    .foregroundStyle(palette.accent)
                    .padding(.horizontal, DesignTokens.Spacing.md)

                // Quote cards
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(viewModel.state.savedQuotes, id: \.id) { quote in
                        savedQuoteCard(quote)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
            .padding(.top, DesignTokens.Spacing.sm)
            .padding(.bottom, DesignTokens.Spacing.huge)
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
                    .font(.caption2)
                    .foregroundStyle(palette.accent)
            },
            actions: {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Button {
                        viewModel.toggleSaved(quote.id)
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .font(.caption)
                            .foregroundStyle(palette.accent)
                    }
                    .buttonStyle(.plain)

                    Button {
                        #if canImport(UIKit)
                        UIPasteboard.general.string = viewModel.copyQuoteText(quote)
                        #endif
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundStyle(palette.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SavedView()
    }
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
