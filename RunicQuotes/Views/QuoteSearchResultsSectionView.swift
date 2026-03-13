//
//  QuoteSearchResultsSectionView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
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
            palette: self.palette,
            cornerRadius: DesignTokens.CornerRadius.xl,
            contentPadding: DesignTokens.Spacing.md,
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                SectionLabel(title: "Search Results", palette: self.palette)

                MetaRow(
                    items: [self.currentCollection.displayName, "\(self.results.count) matches"],
                    palette: self.palette,
                )

                if self.results.isEmpty {
                    Text("No matching lines surfaced in \(self.currentCollection.displayName) yet.")
                        .font(DesignTokens.Typography.supportingBody)
                        .foregroundStyle(self.palette.textSecondary)
                } else {
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        ForEach(self.results.prefix(4)) { result in
                            Button {
                                self.onSelect(result)
                            } label: {
                                QuoteListRow(
                                    palette: self.palette,
                                    runicSnippet: "",
                                    quoteText: result.latinText,
                                    author: result.author,
                                    metadata: [self.currentCollection.displayName],
                                    badge: {
                                        EmptyView()
                                    },
                                    footer: {
                                        HStack {
                                            Label("Open", systemImage: "arrow.up.left")
                                                .font(DesignTokens.Typography.controlLabel)
                                                .foregroundStyle(self.palette.accent)

                                            Spacer(minLength: 0)
                                        }
                                    },
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
