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
    @Environment(\.runicTheme) private var runicTheme
    @Query(filter: #Predicate<Quote> { !$0.isDeleted && !$0.isHidden })
    private var quotes: [Quote]

    private var palette: AppThemePalette {
        .themed(runicTheme, for: colorScheme)
    }

    // MARK: - Body

    var body: some View {
        LiquidListScaffold(palette: palette) {
            Section {
                HeroHeader(
                    eyebrow: "Collections",
                    title: "Curated Shelves",
                    subtitle: "Browse by tone, then continue reading on Home.",
                    meta: ["\(quotes.count) visible quotes", "\(QuotePack.catalog.count) quote packs"],
                    palette: palette
                )
                .listRowInsets(EdgeInsets(
                    top: DesignTokens.Spacing.lg,
                    leading: DesignTokens.Spacing.md,
                    bottom: DesignTokens.Spacing.md,
                    trailing: DesignTokens.Spacing.md
                ))
            }

            Section {
                quotePacksLink
            }

            Section {
                ForEach(QuoteCollection.allCases) { collection in
                    collectionCard(for: collection)
                }
            }
        }
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
            EditorialCard(
                palette: palette,
                tone: collection == .all ? .hero : .primary,
                cornerRadius: DesignTokens.CornerRadius.xl,
                shadowRadius: DesignTokens.Elevation.medium,
                contentPadding: DesignTokens.Spacing.md
            ) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                            SectionLabel(title: "Collection", palette: palette)
                            Label(collection.displayName, systemImage: collection.systemImage)
                                .font(DesignTokens.Typography.cardTitle)
                                .foregroundStyle(palette.textPrimary)
                        }

                        Spacer()

                        Text("\(count) quotes")
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(palette.textPrimary)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            .background {
                                Capsule()
                                    .fill(palette.bannerBackground)
                            }
                    }

                    Text(collection.heroRunicText)
                        .font(.system(size: 34, weight: .medium, design: .serif))
                        .foregroundStyle(palette.runeText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(collection.heroLatinText)
                        .font(DesignTokens.Typography.sectionTitle)
                        .foregroundStyle(palette.textPrimary)

                    Text(collection.subtitle)
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(palette.textSecondary)
                        .lineLimit(2)

                    HStack(spacing: DesignTokens.Spacing.sm) {
                        MetaRow(items: [collection.displayName, "\(count) quotes"], palette: palette)

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(palette.accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
            EditorialCard(
                palette: palette,
                tone: .hero,
                cornerRadius: DesignTokens.CornerRadius.xxl,
                shadowRadius: DesignTokens.Elevation.medium,
                contentPadding: DesignTokens.Spacing.md
            ) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        SectionLabel(title: "Quote Packs", palette: palette)

                        Text("Expand your wisdom library")
                            .font(DesignTokens.Typography.sectionTitle)
                            .foregroundStyle(palette.textPrimary)

                        Text("Curated additions that feel like collectible volumes, not utilities.")
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xxs) {
                        Text("\(QuotePack.catalog.count) packs")
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(palette.textTertiary)

                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                            .foregroundStyle(palette.accent)
                    }
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
