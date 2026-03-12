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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query private var quotes: [Quote]
    @Query private var allPreferences: [UserPreferences]

    private var palette: AppThemePalette {
        .adaptive(for: colorScheme)
    }

    private var preferences: UserPreferences? {
        allPreferences.first
    }

    private var savedQuotes: [Quote] {
        guard let prefs = preferences else { return [] }
        let savedIDs = prefs.savedQuoteIDs
        return quotes.filter { savedIDs.contains($0.id) }
    }

    // MARK: - Body

    var body: some View {
        Group {
            if savedQuotes.isEmpty {
                emptyState
            } else {
                savedList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .navigationTitle("Saved")
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
                Text("\(savedQuotes.count) saved")
                    .font(.subheadline)
                    .foregroundStyle(palette.accent)
                    .padding(.horizontal, DesignTokens.Spacing.md)

                // Quote cards
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(savedQuotes, id: \.id) { quote in
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
    private func savedQuoteCard(_ quote: Quote) -> some View {
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
                        toggleSaved(quote)
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .font(.caption)
                            .foregroundStyle(palette.accent)
                    }
                    .buttonStyle(.plain)

                    Button {
                        #if canImport(UIKit)
                        UIPasteboard.general.string = quote.textLatin
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

    // MARK: - Actions

    private func toggleSaved(_ quote: Quote) {
        guard let prefs = preferences else { return }
        prefs.toggleSavedQuote(quote.id)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SavedView()
    }
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
