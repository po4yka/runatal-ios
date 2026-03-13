//
//  CollectionCoverCarousel.swift
//  RunicQuotes
//
//  Created by Codex on 2026-02-13.
//

import SwiftUI

/// Horizontal collection selector with cover cards for quick browsing.
struct CollectionCoverCarousel: View {
    let covers: [QuoteCollectionCover]
    let selectedCollection: QuoteCollection
    let script: RunicScript
    let font: RunicFont
    let palette: AppThemePalette
    let onCollectionSelected: (QuoteCollection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HeroHeader(
                eyebrow: "Collections",
                title: selectedCollection.displayName,
                subtitle: selectedCollection.subtitle,
                meta: ["\(selectedCollection == .all ? totalQuoteCount : quoteCount(for: selectedCollection)) passages"],
                palette: palette
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(covers) { cover in
                        CollectionCoverCardView(
                            cover: cover,
                            isSelected: cover.collection == selectedCollection,
                            script: script,
                            font: font,
                            palette: palette,
                            onSelect: onCollectionSelected
                        )
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.xxs)
            }
            .scrollClipDisabled()
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    private func quoteCount(for collection: QuoteCollection) -> Int {
        covers.first(where: { $0.collection == collection })?.quoteCount ?? 0
    }

    private var totalQuoteCount: Int {
        covers.first(where: { $0.collection == .all })?.quoteCount ?? covers.map(\.quoteCount).max() ?? 0
    }
}
