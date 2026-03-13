//
//  QuoteCardView.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import SwiftUI

/// Reusable quote card component used across SearchView, SavedView, and ArchiveView.
/// Displays a glass card with runic snippet, quote text, author, and configurable
/// trailing badge and bottom actions.
struct QuoteCardView<Badge: View, Actions: View>: View {

    // MARK: - Properties

    let runicSnippet: String
    let quoteText: String
    let author: String
    @ViewBuilder let badge: Badge
    @ViewBuilder let actions: Actions

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme

    private var palette: AppThemePalette {
        .themed(self.runicTheme, for: self.colorScheme)
    }

    // MARK: - Body

    var body: some View {
        EditorialCard(
            palette: self.palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: DesignTokens.Elevation.low,
            contentPadding: DesignTokens.Spacing.md,
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        SectionLabel(title: "Passage", palette: self.palette)

                        Text(self.runicSnippet.isEmpty ? "ᚱᚢᚾᚨ" : self.runicSnippet)
                            .font(.caption)
                            .foregroundStyle(self.palette.runeText)
                            .lineLimit(2)
                    }

                    Spacer(minLength: DesignTokens.Spacing.sm)

                    self.badge
                }

                Text("“\(self.quoteText)”")
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(self.palette.textPrimary)
                    .lineLimit(4)

                MetaRow(items: [self.author], palette: self.palette)

                if Actions.self != EmptyView.self {
                    ActionBar(palette: self.palette) {
                        Spacer(minLength: 0)
                        self.actions
                    }
                }
            }
        }
    }
}

// MARK: - Convenience Initializer (badge as text)

extension QuoteCardView where Badge == Text {
    /// Creates a quote card with a simple text badge (e.g., collection name).
    init(
        runicSnippet: String,
        quoteText: String,
        author: String,
        badgeText: String,
        @ViewBuilder actions: () -> Actions,
    ) {
        self.init(
            runicSnippet: runicSnippet,
            quoteText: quoteText,
            author: author,
            badge: {
                Text(badgeText)
                    .font(DesignTokens.Typography.metadata)
                    .foregroundStyle(AppThemePalette.themed(.obsidian, for: .dark).accent)
            },
            actions: actions,
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 16) {
            QuoteCardView(
                runicSnippet: "\u{16A0}\u{16B1}\u{16BA}",
                quoteText: "Strength grows in silence.",
                author: "Norse Proverb",
                badge: {
                    Text("Motivation")
                        .font(DesignTokens.Typography.listMeta)
                        .foregroundStyle(.blue)
                },
                actions: {
                    Image(systemName: "bookmark")
                        .font(.caption)
                        .foregroundStyle(.gray)
                },
            )
        }
        .padding()
    }
}
