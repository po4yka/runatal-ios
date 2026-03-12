//
//  QuotePacksView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI

/// Browse and search the catalog of quote packs.
struct QuotePacksView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var selectedPack: QuotePack?

    private var palette: AppThemePalette {
        .adaptive(for: colorScheme)
    }

    private var filteredPacks: [QuotePack] {
        guard !searchText.isEmpty else { return QuotePack.catalog }
        let query = searchText.lowercased()
        return QuotePack.catalog.filter {
            $0.title.lowercased().contains(query) ||
            $0.subtitle.lowercased().contains(query)
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                headerSection

                if filteredPacks.isEmpty {
                    emptyState
                } else {
                    packList
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.huge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
        .searchable(text: $searchText, prompt: "Search packs")
        .navigationTitle("Quote Packs")
        .navigationDestination(item: $selectedPack) { pack in
            QuotePackDetailView(pack: pack)
        }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerSection: some View {
        Text("Expand your wisdom library")
            .font(.subheadline)
            .foregroundStyle(palette.textSecondary)
            .padding(.top, DesignTokens.Spacing.xs)
    }

    // MARK: - Pack List

    @ViewBuilder
    private var packList: some View {
        LazyVStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(filteredPacks) { pack in
                packRow(for: pack)
            }
        }
    }

    // MARK: - Pack Row

    @ViewBuilder
    private func packRow(for pack: QuotePack) -> some View {
        Button {
            selectedPack = pack
        } label: {
            GlassCard(
                intensity: .light,
                cornerRadius: DesignTokens.CornerRadius.lg,
                shadowRadius: 4
            ) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    // Runic glyph
                    Text(pack.runicGlyph)
                        .font(.title)
                        .foregroundStyle(palette.runeText)
                        .frame(width: 40, alignment: .center)

                    // Title, subtitle, count
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text(pack.title)
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)

                        Text(pack.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(1)

                        Text("\(pack.quoteCount) quotes")
                            .font(.caption)
                            .foregroundStyle(palette.textTertiary)
                    }

                    Spacer()

                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(palette.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("pack_\(pack.id)")
        .accessibilityLabel("\(pack.title), \(pack.quoteCount) quotes")
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Spacer(minLength: DesignTokens.Spacing.huge)

            Text("\u{16C8}\u{16A8}\u{16B2}")
                .font(.system(size: 48))
                .foregroundStyle(palette.runeText.opacity(0.3))

            Text("No packs found")
                .font(.title3.weight(.semibold))
                .foregroundStyle(palette.textPrimary)

            Text("Try a different search term or browse the full catalog")
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: DesignTokens.Spacing.huge)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        QuotePacksView()
    }
}
