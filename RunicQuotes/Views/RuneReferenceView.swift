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
    @State private var selectedScript: RunicScript = .elder
    @State private var searchText = ""

    private var palette: AppThemePalette {
        .adaptive(for: colorScheme)
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
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                scriptPicker

                scriptHeader

                runeGrid
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.top, DesignTokens.Spacing.xs)
            .padding(.bottom, DesignTokens.Spacing.huge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
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
        Picker("Script", selection: $selectedScript) {
            ForEach(RunicScript.allCases) { script in
                Text(script.displayName).tag(script)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, DesignTokens.Spacing.xxs)
    }

    // MARK: - Script Header

    @ViewBuilder
    private var scriptHeader: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Text(selectedScript.displayName)
                .font(.title2.bold())
                .foregroundStyle(palette.textPrimary)

            Text(RuneInfo.subtitle(for: selectedScript))
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
        }
        .padding(.horizontal, DesignTokens.Spacing.xxs)
    }

    // MARK: - Rune Grid

    @ViewBuilder
    private var runeGrid: some View {
        if filteredRunes.isEmpty {
            ContentUnavailableView.search
                .foregroundStyle(palette.textPrimary, palette.textSecondary)
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
        GlassCard(
            intensity: .light,
            cornerRadius: DesignTokens.CornerRadius.md,
            shadowRadius: 4
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
