//
//  RuneReferenceView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-12.
//

import SwiftUI

/// Searchable grid of rune glyphs for all 3 scripts (Elder Futhark, Younger Futhark, Cirth).
struct RuneReferenceView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @State private var selectedScript: RunicScript = .elder
    @State private var searchText = ""

    private var palette: AppThemePalette {
        .themed(runicTheme, for: colorScheme)
    }

    private var runes: [RuneInfo] {
        RuneInfo.runes(for: selectedScript)
    }

    private var filteredRunes: [RuneInfo] {
        guard !searchText.isEmpty else { return runes }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return runes.filter {
            $0.name.localizedStandardContains(query)
            || $0.meaning.localizedStandardContains(query)
            || $0.sound.localizedStandardContains(query)
            || $0.glyph.localizedStandardContains(query)
        }
    }

    // MARK: - Body

    var body: some View {
        ScreenScaffold(palette: palette) {
            HeroHeader(
                eyebrow: "Rune Reference",
                title: selectedScript.displayName,
                subtitle: RuneInfo.subtitle(for: selectedScript),
                meta: ["\(filteredRunes.count) visible runes"],
                palette: palette
            )

            scriptPicker
            runeGrid
        }
        .navigationTitle("Rune Reference")
        .searchable(text: $searchText, prompt: "Search runes...")
        .navigationDestination(for: String.self) { runeID in
            if let rune = RuneInfo.runes(for: selectedScript).first(where: { $0.id == runeID }) {
                RuneDetailView(rune: rune)
            }
        }
    }

    // MARK: - Script Picker

    @ViewBuilder
    private var scriptPicker: some View {
        GlassScriptSelector(
            selectedScript: Binding(
                get: { selectedScript },
                set: { selectedScript = $0 }
            )
        )
        .padding(.horizontal, DesignTokens.Spacing.xxs)
        .background {
            InsetCard(palette: palette, cornerRadius: DesignTokens.CornerRadius.xl) {
                EmptyView()
            }
        }
    }

    // MARK: - Rune Grid

    @ViewBuilder
    private var runeGrid: some View {
        if filteredRunes.isEmpty {
            EditorialEmptyState(
                palette: palette,
                icon: "character.book.closed",
                eyebrow: "No runes",
                title: "Nothing matched",
                message: "Search by name, sound, meaning, or glyph."
            )
        } else {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.xs),
                    count: 4
                ),
                spacing: DesignTokens.Spacing.xs
            ) {
                ForEach(filteredRunes) { rune in
                    NavigationLink(value: rune.id) {
                        runeCell(rune)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Rune Cell

    @ViewBuilder
    private func runeCell(_ rune: RuneInfo) -> some View {
        EditorialCard(
            palette: palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.md,
            shadowRadius: DesignTokens.Elevation.low,
            contentPadding: DesignTokens.Spacing.sm
        ) {
            VStack(spacing: DesignTokens.Spacing.xxs) {
                Text(rune.glyph)
                    .font(.system(size: 32))
                    .foregroundStyle(palette.runeText)
                    .frame(height: 40)

                Text(rune.name)
                    .font(.caption.bold())
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(rune.meaning)
                    .font(.caption)
                    .foregroundStyle(palette.textTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityLabel("\(rune.name), \(rune.meaning), sound \(rune.sound)")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RuneReferenceView()
    }
}
