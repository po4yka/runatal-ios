//
//  QuotePacksView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI

/// Browse and search the catalog of quote packs.
struct QuotePacksView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @State private var searchText = ""
    @State private var selectedPack: QuotePack?

    private var palette: AppThemePalette {
        .themed(runicTheme, for: colorScheme)
    }

    private var filteredPacks: [QuotePack] {
        guard !searchText.isEmpty else { return QuotePack.catalog }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return QuotePack.catalog.filter {
            $0.title.localizedStandardContains(query) ||
            $0.subtitle.localizedStandardContains(query)
        }
    }

    // MARK: - Body

    var body: some View {
        ScreenScaffold(palette: palette) {
            HeroHeader(
                eyebrow: "Quote Packs",
                title: "Collectible Volumes",
                subtitle: "Curated additions that extend the library without changing the rhythm of reading.",
                meta: ["\(filteredPacks.count) available"],
                palette: palette
            )

            if filteredPacks.isEmpty {
                EditorialEmptyState(
                    palette: palette,
                    icon: "books.vertical",
                    eyebrow: "No packs",
                    title: "Nothing matched that search",
                    message: "Try a broader title or clear the search field."
                )
            } else {
                packList
            }
        }
        .searchable(text: $searchText, prompt: "Search packs")
        .navigationTitle("Quote Packs")
        .navigationDestination(item: $selectedPack) { pack in
            QuotePackDetailView(pack: pack)
        }
    }

    // MARK: - Pack List

    @ViewBuilder
    private var packList: some View {
        LazyVStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(filteredPacks) { pack in
                packRow(for: pack)
            }
        }
    }

    // MARK: - Pack Row

    @ViewBuilder
    private func packRow(for pack: QuotePack) -> some View {
        Button {
            selectedPack = pack
        } label: {
            EditorialCard(
                palette: palette,
                tone: .primary,
                cornerRadius: DesignTokens.CornerRadius.xl,
                shadowRadius: DesignTokens.Elevation.low,
                contentPadding: DesignTokens.Spacing.md
            ) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Text(pack.runicGlyph)
                        .font(.system(size: 32, weight: .medium, design: .serif))
                        .foregroundStyle(palette.runeText)
                        .frame(width: 44, alignment: .center)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        SectionLabel(title: "Pack", palette: palette)
                        Text(pack.title)
                            .font(DesignTokens.Typography.cardTitle)
                            .foregroundStyle(palette.textPrimary)

                        Text(pack.subtitle)
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(2)

                        Text("\(pack.quoteCount) quotes")
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(palette.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(palette.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pack_\(pack.id)")
        .accessibilityLabel("\(pack.title), \(pack.quoteCount) quotes")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        QuotePacksView()
    }
}
