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
        VStack(alignment: .leading, spacing: 10) {
            header

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
                .padding(.vertical, 6)
            }
            .scrollClipDisabled()
        }
        .padding(.horizontal)
    }

    private var header: some View {
        HStack {
            Text("Collections")
                .font(.headline)
                .foregroundStyle(palette.primaryText)

            Spacer()

            Text(selectedCollection.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.tertiaryText)
        }
    }
}
