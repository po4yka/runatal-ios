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
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Search Results")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            if results.isEmpty {
                Text("No matches found in \(currentCollection.displayName).")
                    .font(.caption)
                    .foregroundStyle(palette.textTertiary)
            } else {
                VStack(spacing: DesignTokens.Spacing.xs) {
                    ForEach(results.prefix(4)) { result in
                        Button {
                            onSelect(result)
                        } label: {
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                                    Text(result.latinText)
                                        .font(.subheadline)
                                        .foregroundStyle(palette.textPrimary)
                                        .lineLimit(1)

                                    Text("— \(result.author)")
                                        .font(.caption)
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
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                                    .fill(.ultraThinMaterial)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
    }
}
