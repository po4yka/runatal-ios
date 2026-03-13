//
//  CollectionsView.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import SwiftData
import SwiftUI
import TipKit

/// Browse quotes organized by collection in a 2-column grid.
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
            EditorialCard(
                palette: self.palette,
                tone: collection == .all ? .hero : .primary,
                cornerRadius: DesignTokens.CornerRadius.xl,
                shadowRadius: DesignTokens.Elevation.medium,
                contentPadding: DesignTokens.Spacing.md,
            ) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                            SectionLabel(title: "Collection", palette: self.palette)
                            Label(collection.displayName, systemImage: collection.systemImage)
                                .font(DesignTokens.Typography.cardTitle)
                                .foregroundStyle(self.palette.textPrimary)
                        }

                        Spacer()

                        Text("\(count) quotes")
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(self.palette.textPrimary)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            .background {
                                Capsule()
                                    .fill(self.palette.bannerBackground)
                            }
                    }

                    Text(collection.heroRunicText)
                        .font(.system(size: 34, weight: .medium, design: .serif))
                        .foregroundStyle(self.palette.runeText)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(collection.heroLatinText)
                        .font(DesignTokens.Typography.sectionTitle)
                        .foregroundStyle(self.palette.textPrimary)

                    Text(collection.subtitle)
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(self.palette.textSecondary)
                        .lineLimit(2)

                    HStack(spacing: DesignTokens.Spacing.sm) {
                        MetaRow(items: [collection.displayName, "\(count) quotes"], palette: self.palette)

                        Spacer()

                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(self.palette.accent)
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

    private var quotePacksLink: some View {
        NavigationLink(value: "quotePacks") {
            EditorialCard(
                palette: self.palette,
                tone: .hero,
                cornerRadius: DesignTokens.CornerRadius.xxl,
                shadowRadius: DesignTokens.Elevation.medium,
                contentPadding: DesignTokens.Spacing.md,
            ) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        SectionLabel(title: "Quote Packs", palette: self.palette)

                        Text("Expand your wisdom library")
                            .font(DesignTokens.Typography.sectionTitle)
                            .foregroundStyle(self.palette.textPrimary)

                        Text("Curated additions that feel like collectible volumes, not utilities.")
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(self.palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xxs) {
                        Text("\(QuotePack.catalog.count) packs")
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(self.palette.textTertiary)

                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title3)
                            .foregroundStyle(self.palette.accent)
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
