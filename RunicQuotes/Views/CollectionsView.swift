//
//  CollectionsView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI
import SwiftData

/// Browse quotes organized by collection in a 2-column grid.
struct CollectionsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(filter: #Predicate<Quote> { !$0.isDeleted && !$0.isHidden })
    private var quotes: [Quote]

    private var palette: AppThemePalette {
        .adaptive(for: colorScheme)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: DesignTokens.Spacing.sm),
                        GridItem(.flexible(), spacing: DesignTokens.Spacing.sm)
                    ],
                    spacing: DesignTokens.Spacing.sm
                ) {
                    ForEach(QuoteCollection.allCases) { collection in
                        collectionCard(for: collection)
                    }
                }

                // Quote Packs link
                quotePacksLink
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.top, DesignTokens.Spacing.sm)
            .padding(.bottom, DesignTokens.Spacing.huge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .navigationTitle("Collections")
        .navigationDestination(for: String.self) { destination in
            if destination == "quotePacks" {
                QuotePacksView()
            }
        }
    }

    // MARK: - Collection Card

    @ViewBuilder
    private func collectionCard(for collection: QuoteCollection) -> some View {
        let count = quoteCount(for: collection)

        Button {
            switchToCollection(collection)
        } label: {
            GlassCard(
                intensity: .light,
                cornerRadius: DesignTokens.CornerRadius.lg,
                shadowRadius: 6
            ) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(collection.heroRunicText)
                        .font(.title2)
                        .foregroundStyle(palette.runeText.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer(minLength: DesignTokens.Spacing.lg)

                    Text(collection.displayName)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    Text(collection.subtitle)
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(1)

                    HStack(spacing: DesignTokens.Spacing.xxs) {
                        Circle()
                            .fill(palette.accent)
                            .frame(width: 3, height: 3)

                        Text("\(count) quotes")
                            .font(.caption2)
                            .foregroundStyle(palette.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 90)
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("collection_\(collection.rawValue)")
        .accessibilityLabel("\(collection.displayName) collection, \(count) quotes")
    }

    // MARK: - Quote Packs Link

    @ViewBuilder
    private var quotePacksLink: some View {
        NavigationLink(value: "quotePacks") {
            GlassCard(
                intensity: .light,
                cornerRadius: DesignTokens.CornerRadius.lg,
                shadowRadius: 4
            ) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Text("\u{16B1}")
                        .font(.title2)
                        .foregroundStyle(palette.runeText)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text("Quote Packs")
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)

                        Text("Expand your wisdom library")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(palette.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("quote_packs_link")
    }

    // MARK: - Helpers

    private func quoteCount(for collection: QuoteCollection) -> Int {
        if collection == .all {
            return quotes.count
        }
        return quotes.filter { $0.collection == collection }.count
    }

    private func switchToCollection(_ collection: QuoteCollection) {
        NotificationCenter.default.post(
            name: .switchToTab,
            object: nil,
            userInfo: ["tab": AppTab.home, "collection": collection]
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CollectionsView()
    }
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
}
