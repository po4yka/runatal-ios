//
//  RuneReferenceView.swift
//  RunicQuotes
//
//  Created by Claude on 12.03.26.
//

import SwiftUI

/// Searchable grid of rune glyphs for all 3 scripts (Elder Futhark, Younger Futhark, Cirth).
struct RuneReferenceView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme
    @State private var selectedScript: RunicScript = .elder
    @State private var searchText = ""

    private var palette: AppThemePalette {
        .themed(self.runicTheme, for: self.colorScheme)
    }

    private var runes: [RuneInfo] {
        RuneInfo.runes(for: self.selectedScript)
    }

    private var filteredRunes: [RuneInfo] {
        guard !self.searchText.isEmpty else { return self.runes }
        let query = self.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return self.runes.filter {
            $0.name.localizedStandardContains(query)
                || $0.meaning.localizedStandardContains(query)
                || $0.sound.localizedStandardContains(query)
                || $0.glyph.localizedStandardContains(query)
        }
    }

    // MARK: - Body

    var body: some View {
        LiquidContentScaffold(
            palette: self.palette,
            spacing: DesignTokens.Spacing.lg,
            showBackgroundExtension: false,
        ) {
            HeroHeader(
                eyebrow: "Rune Reference",
                title: self.selectedScript.displayName,
                subtitle: RuneInfo.subtitle(for: self.selectedScript),
                meta: ["\(self.filteredRunes.count) visible runes"],
                palette: self.palette,
            )

            self.scriptPicker
            self.runeGrid
        }
        .navigationTitle("Rune Reference")
        .searchable(text: self.$searchText, prompt: "Search runes...")
        .navigationDestination(for: String.self) { runeID in
            if let rune = RuneInfo.runes(for: selectedScript).first(where: { $0.id == runeID }) {
                RuneDetailView(rune: rune)
            }
        }
    }

    // MARK: - Script Picker

    private var scriptPicker: some View {
        GlassScriptSelector(
            selectedScript: Binding(
                get: { self.selectedScript },
                set: { self.selectedScript = $0 },
            ),
        )
    }

    // MARK: - Rune Grid

    @ViewBuilder
    private var runeGrid: some View {
        if self.filteredRunes.isEmpty {
            EditorialEmptyState(
                palette: self.palette,
                icon: "character.book.closed",
                eyebrow: "No runes",
                title: "Nothing matched",
                message: "Search by name, sound, meaning, or glyph.",
            )
        } else {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: DesignTokens.Spacing.xs),
                    count: 4,
                ),
                spacing: DesignTokens.Spacing.xs,
            ) {
                ForEach(self.filteredRunes) { rune in
                    NavigationLink(value: rune.id) {
                        self.runeCell(rune)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Rune Cell

    private func runeCell(_ rune: RuneInfo) -> some View {
        ContentPlate(
            palette: self.palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.md,
            shadowRadius: 0,
            contentPadding: DesignTokens.Spacing.sm,
        ) {
            VStack(spacing: DesignTokens.Spacing.xxs) {
                Text(rune.glyph)
                    .font(.system(size: 32))
                    .foregroundStyle(self.palette.runeText)
                    .frame(height: 40)

                Text(rune.name)
                    .font(DesignTokens.Typography.controlLabel)
                    .foregroundStyle(self.palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(rune.meaning)
                    .font(DesignTokens.Typography.listMeta)
                    .foregroundStyle(self.palette.textTertiary)
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
