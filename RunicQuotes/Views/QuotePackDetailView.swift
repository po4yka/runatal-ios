//
//  QuotePackDetailView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI

/// Detail view for a single quote pack with description, preview quotes, and install action.
struct QuotePackDetailView: View {
    let pack: QuotePack
    @Environment(\.colorScheme) private var colorScheme

    private var palette: AppThemePalette {
        .adaptive(for: colorScheme)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Header
                packHeader

                // Description
                Text(pack.description)
                    .font(.body)
                    .foregroundStyle(palette.textSecondary)

                // Preview section
                previewSection
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.huge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .navigationTitle(pack.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pack Header

    @ViewBuilder
    private var packHeader: some View {
        GlassCard(
            intensity: .medium,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: 6
        ) {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(pack.runicGlyph)
                    .font(.system(size: 48))
                    .foregroundStyle(palette.runeText)

                Text(pack.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(palette.textPrimary)

                Text("\(pack.quoteCount) quotes \u{00B7} \(pack.subtitle)")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Preview Section

    @ViewBuilder
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Preview")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            ForEach(Array(pack.previewQuotes.enumerated()), id: \.offset) { index, quote in
                HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.accent)
                        .frame(width: 20, alignment: .trailing)

                    Text("\"\(quote)\"")
                        .font(.body)
                        .foregroundStyle(palette.textPrimary)
                        .italic()
                }
                .padding(.vertical, DesignTokens.Spacing.xxs)

                if index < pack.previewQuotes.count - 1 {
                    Divider()
                        .overlay(palette.separator)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        QuotePackDetailView(pack: .sample)
    }
}
