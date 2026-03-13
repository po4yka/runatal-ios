//
//  QuoteSearchResultsSectionView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-13.
//

import SwiftUI

/// Inline quote search results shown on the home screen.
struct QuoteSearchResultsSectionView: View {
    let currentCollection: QuoteCollection
    let results: [QuoteSearchResult]
    let palette: AppThemePalette
    let onSelect: (QuoteSearchResult) -> Void

    var body: some View {
        InsetCard(
            palette: palette,
            cornerRadius: DesignTokens.CornerRadius.xl,
            contentPadding: DesignTokens.Spacing.md
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                SectionLabel(title: "Search Results", palette: palette)

                MetaRow(
                    items: [currentCollection.displayName, "\(results.count) matches"],
                    palette: palette
                )

                if results.isEmpty {
                    Text("No matching lines surfaced in \(currentCollection.displayName) yet.")
                        .font(DesignTokens.Typography.supportingBody)
                        .foregroundStyle(palette.textSecondary)
                } else {
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        ForEach(results.prefix(4)) { result in
                            Button {
                                onSelect(result)
                            } label: {
                                QuoteListRow(
                                    palette: palette,
                                    runicSnippet: "",
                                    quoteText: result.latinText,
                                    author: result.author,
                                    metadata: [currentCollection.displayName],
                                    badge: {
                                        EmptyView()
                                    },
                                    footer: {
                                        HStack {
                                            Label("Open", systemImage: "arrow.up.left")
                                                .font(DesignTokens.Typography.controlLabel)
                                                .foregroundStyle(palette.accent)

                                            Spacer(minLength: 0)
                                        }
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
