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
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(palette.textSecondary)
                } else {
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        ForEach(results.prefix(4)) { result in
                            Button {
                                onSelect(result)
                            } label: {
                                HStack(spacing: DesignTokens.Spacing.sm) {
                                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                                        Text(result.latinText)
                                            .font(DesignTokens.Typography.bodyEmphasis)
                                            .foregroundStyle(palette.textPrimary)
                                            .lineLimit(2)

                                        Text("— \(result.author)")
                                            .font(DesignTokens.Typography.label)
                                            .foregroundStyle(palette.textTertiary)
                                            .lineLimit(1)
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.up.left")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(palette.textSecondary)
                                }
                                .padding(.horizontal, DesignTokens.Spacing.sm)
                                .padding(.vertical, DesignTokens.Spacing.sm)
                                .background {
                                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                        .fill(palette.bannerBackground)
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                        .strokeBorder(
                                            palette.cardStroke,
                                            lineWidth: DesignTokens.Stroke.hairline
                                        )
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
