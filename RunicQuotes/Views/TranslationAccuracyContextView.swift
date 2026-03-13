//
//  TranslationAccuracyContextView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct TranslationAccuracyContextView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme

    var body: some View {
        ScreenScaffold(palette: palette) {
            VStack(spacing: DesignTokens.Spacing.xl) {
                HeroHeader(
                    eyebrow: "Reference",
                    title: "Accuracy & Context",
                    subtitle: "Structured translation is conservative. Strict mode refuses output when the bundled evidence cannot support it.",
                    meta: ["Offline", "Curated", "Educational"],
                    palette: palette
                )

                EditorialCard(palette: palette, tone: .primary) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("How to read the results")
                            .font(DesignTokens.Typography.cardTitle)
                            .foregroundStyle(palette.textPrimary)

                        Text("Strict uses only curated attestations, phrase templates, and lexicon coverage. Readable and Decorative may preserve or paraphrase unsupported words, but those results are marked as approximations.")
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(palette.textSecondary)
                    }
                }

                EditorialCard(palette: palette, tone: .secondary) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Layer meanings")
                            .font(DesignTokens.Typography.cardTitle)
                            .foregroundStyle(palette.textPrimary)

                        labelRow(title: "Normalized", body: "Editorial reading form used for dictionary and morphology alignment.")
                        labelRow(title: "Diplomatic", body: "Runic-era spelling layer used before glyph rendering.")
                        labelRow(title: "Provenance", body: "Curated sources or corpus references that support the result.")
                    }
                }

                NavigationLink {
                    RuneReferenceView()
                } label: {
                    GlassCard(intensity: .medium) {
                        HStack {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                                Text("Open Rune Reference")
                                    .font(DesignTokens.Typography.cardTitle)
                                    .foregroundStyle(palette.textPrimary)
                                Text("Cross-check the script shapes and historical notes.")
                                    .font(DesignTokens.Typography.metadata)
                                    .foregroundStyle(palette.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "character.book.closed")
                                .foregroundStyle(palette.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("translation_rune_reference_link")
            }
        }
        .accessibilityIdentifier("translation_accuracy_view")
        .navigationTitle(String(localized: "translation.accuracy.title"))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var palette: AppThemePalette {
        .themed(runicTheme, for: colorScheme)
    }

    private func labelRow(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)
            Text(body)
                .font(DesignTokens.Typography.metadata)
                .foregroundStyle(palette.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        TranslationAccuracyContextView()
    }
}
