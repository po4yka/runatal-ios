//
//  CollectionCoverCarousel.swift
//  RunicQuotes
//
//  Created by Claude on 13.02.26.
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
                title: self.selectedCollection.displayName,
                subtitle: self.selectedCollection.subtitle,
                meta: ["\(self.selectedCollection == .all ? self.totalQuoteCount : self.quoteCount(for: self.selectedCollection)) passages"],
                palette: self.palette,
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(self.covers) { cover in
                        CollectionCoverCardView(
                            cover: cover,
                            isSelected: cover.collection == self.selectedCollection,
                            script: self.script,
                            font: self.font,
                            palette: self.palette,
                            onSelect: self.onCollectionSelected,
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
        self.covers.first(where: { $0.collection == collection })?.quoteCount ?? 0
    }

    private var totalQuoteCount: Int {
        self.covers.first(where: { $0.collection == .all })?.quoteCount ?? self.covers.map(\.quoteCount).max() ?? 0
    }
}
