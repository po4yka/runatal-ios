//
//  QuoteCardView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
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
    let badge: Badge
    let actions: Actions

    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        .adaptive(for: colorScheme)
    }

    // MARK: - Initialization

    init(
        runicSnippet: String,
        quoteText: String,
        author: String,
        @ViewBuilder badge: () -> Badge,
        @ViewBuilder actions: () -> Actions
    ) {
        self.runicSnippet = runicSnippet
        self.quoteText = quoteText
        self.author = author
        self.badge = badge()
        self.actions = actions()
    }

    // MARK: - Body

    var body: some View {
        GlassCard(
            intensity: .light,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: 4
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                // Top row: runic text + trailing badge
                HStack(alignment: .top) {
                    Text(runicSnippet)
                        .font(.caption2)
                        .foregroundStyle(palette.runeText.opacity(0.6))
                        .lineLimit(1)

                    Spacer()

                    badge
                }

                // Quote text
                Text("\u{201C}\(quoteText)\u{201D}")
                    .font(.body)
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(3)

                // Bottom row: author + actions
                HStack {
                    Text(author)
                        .font(.subheadline)
                        .foregroundStyle(palette.accent)

                    Spacer()

                    actions
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
        @ViewBuilder actions: () -> Actions
    ) {
        self.init(
            runicSnippet: runicSnippet,
            quoteText: quoteText,
            author: author,
            badge: {
                Text(badgeText)
                    .font(.caption2)
                    .foregroundStyle(AppThemePalette.adaptive(for: .dark).accent)
            },
            actions: actions
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
                        .font(.caption2)
                        .foregroundStyle(.blue)
                },
                actions: {
                    Image(systemName: "bookmark")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            )
        }
        .padding()
    }
}
