//
//  CollectionsView.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import SwiftData
import SwiftUI
import TipKit

/// Browse quotes organized by curated shelves.
struct CollectionsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @EnvironmentObject private var featureDiscoveryController: FeatureDiscoveryController
    @Query(filter: #Predicate<Quote> { !$0.isSoftDeleted && !$0.isHidden })
    private var quotes: [Quote]

    private var palette: AppThemePalette {
        .themed(self.runicTheme, for: self.colorScheme)
    }

    // MARK: - Body

    var body: some View {
        LiquidListScaffold(palette: self.palette) {
            Section {
                HeroHeader(
                    eyebrow: "Collections",
                    title: "Curated Shelves",
                    subtitle: "Browse by tone, then continue reading on Home.",
                    meta: ["\(self.quotes.count) visible quotes", "\(QuotePack.catalog.count) quote packs"],
                    palette: self.palette,
                )
                .listRowInsets(EdgeInsets(
                    top: DesignTokens.Spacing.lg,
                    leading: DesignTokens.Spacing.md,
                    bottom: DesignTokens.Spacing.md,
                    trailing: DesignTokens.Spacing.md,
                ))
            }

            Section {
                RunicInlineTip(
                    tip: CollectionsHomeStreamTip(),
                    palette: self.palette,
                    refreshID: self.featureDiscoveryController.refreshID,
                    accessibilityIdentifier: "tip_collections_home_stream",
                )
                .listRowInsets(EdgeInsets(
                    top: 0,
                    leading: DesignTokens.Spacing.md,
                    bottom: DesignTokens.Spacing.md,
                    trailing: DesignTokens.Spacing.md,
                ))
            }

            Section {
                self.quotePacksLink
            }

            Section {
                ForEach(QuoteCollection.allCases) { collection in
                    self.collectionCard(for: collection)
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
        let count = self.quoteCount(for: collection)

        Button {
            self.switchToCollection(collection)
        } label: {
            CollectionShelfRow(
                palette: self.palette,
                eyebrow: "Collection",
                title: collection.displayName,
                subtitle: collection.subtitle,
                supporting: collection.heroLatinText,
                meta: [count == 1 ? "1 quote" : "\(count) quotes"],
                leading: {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Label("", systemImage: collection.systemImage)
                            .labelStyle(.iconOnly)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(self.palette.accent)

                        Text(collection.heroRunicText)
                            .font(.system(size: 28, weight: .medium, design: .serif))
                            .foregroundStyle(self.palette.runeText)
                            .lineLimit(2)
                    }
                    .frame(width: 64, alignment: .leading)
                },
                trailing: {
                    VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xxs) {
                        Text("\(count)")
                            .font(DesignTokens.Typography.listMeta)
                            .foregroundStyle(self.palette.textTertiary)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            .background {
                                Capsule()
                                    .fill(self.palette.bannerBackground)
                            }

                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(self.palette.accent)
                    }
                },
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("collection_\(collection.rawValue)")
        .accessibilityLabel("\(collection.displayName) collection, \(count) quotes")
    }

    // MARK: - Quote Packs Link

    private var quotePacksLink: some View {
        NavigationLink(value: "quotePacks") {
            CollectionShelfRow(
                palette: self.palette,
                eyebrow: "Quote Packs",
                title: "Collectible Volumes",
                subtitle: "Curated additions that extend the library without changing the reading rhythm.",
                supporting: "Quote Packs now sit beside the main shelves instead of apart from them.",
                meta: ["\(QuotePack.catalog.count) packs"],
                leading: {
                    Text("ᚠ")
                        .font(.system(size: 30, weight: .medium, design: .serif))
                        .foregroundStyle(self.palette.runeText)
                        .frame(width: 48, height: 48)
                        .background {
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                .fill(self.palette.bannerBackground)
                        }
                },
                trailing: {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(self.palette.accent)
                },
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("quote_packs_link")
    }

    // MARK: - Helpers

    private func quoteCount(for collection: QuoteCollection) -> Int {
        if collection == .all {
            return self.quotes.count
        }
        return self.quotes.count(where: { $0.collection == collection })
    }

    private func switchToCollection(_ collection: QuoteCollection) {
        if collection != .all {
            FeatureDiscoveryEvents.collectionsSelectedCollection.sendDonation()
            CollectionsHomeStreamTip().invalidate(reason: .actionPerformed)
        }

        NotificationCenter.default.post(
            name: .switchToTab,
            object: nil,
            userInfo: ["tab": AppTab.home, "collection": collection],
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CollectionsView()
    }
    .modelContainer(for: [Quote.self, UserPreferences.self], inMemory: true)
    .environmentObject(FeatureDiscoveryController.preview())
}
