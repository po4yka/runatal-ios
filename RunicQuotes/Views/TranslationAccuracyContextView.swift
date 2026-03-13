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
        LiquidListScaffold(palette: palette) {
            Section {
                HeroHeader(
                    eyebrow: "Reference",
                    title: "Accuracy & Context",
                    subtitle: "Structured translation is conservative. Strict mode refuses output when the bundled evidence cannot support it.",
                    meta: ["Offline", "Curated", "Educational"],
                    palette: palette
                )
                .listRowSeparator(.hidden)
                .listRowInsets(
                    EdgeInsets(
                        top: DesignTokens.Spacing.xl,
                        leading: DesignTokens.Spacing.md,
                        bottom: DesignTokens.Spacing.md,
                        trailing: DesignTokens.Spacing.md
                    )
                )
            }

            Section {
                ContentPlate(
                    palette: palette,
                    tone: .primary,
                    cornerRadius: DesignTokens.CornerRadius.xxl,
                    shadowRadius: DesignTokens.Elevation.low
                ) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        SectionLabel(title: "Reading", palette: palette)

                        Text("How to read the results")
                            .font(DesignTokens.Typography.sectionTitle)
                            .foregroundStyle(palette.textPrimary)

                        Text("Strict uses only curated attestations, phrase templates, and lexicon coverage. Readable and Decorative may preserve or paraphrase unsupported words, but those results are marked as approximations.")
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(palette.textSecondary)

                        Text("Source support is English-only in this release. Unsupported input is rejected instead of silently guessing.")
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(palette.textSecondary)
                    }
                }
                .listRowSeparator(.hidden)

                ContentPlate(
                    palette: palette,
                    tone: .secondary,
                    cornerRadius: DesignTokens.CornerRadius.xxl,
                    shadowRadius: DesignTokens.Elevation.low
                ) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        SectionLabel(title: "Evidence", palette: palette)

                        Text("Layer meanings")
                            .font(DesignTokens.Typography.sectionTitle)
                            .foregroundStyle(palette.textPrimary)

                        labelRow(title: "Normalized", body: "Editorial reading form used for dictionary and morphology alignment.")
                        labelRow(title: "Diplomatic", body: "Runic-era spelling layer used before glyph rendering.")
                        labelRow(title: "Provenance", body: "Curated sources or corpus references that support the result.")
                        labelRow(title: "Evidence badges", body: "Attested, Reconstructed, Approximate, and Unsupported summarize how strong the bundled evidence is.")
                    }
                }
                .listRowSeparator(.hidden)
            }

            Section {
                NavigationLink {
                    RuneReferenceView()
                } label: {
                    ContentPlate(
                        palette: palette,
                        tone: .secondary,
                        cornerRadius: DesignTokens.CornerRadius.xxl,
                        shadowRadius: DesignTokens.Elevation.low
                    ) {
                        HStack {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                                Text("Open Rune Reference")
                                    .font(DesignTokens.Typography.cardTitle)
                                    .foregroundStyle(palette.textPrimary)
                                Text("Cross-check script forms, notes, and historical shape guidance.")
                                    .font(DesignTokens.Typography.callout)
                                    .foregroundStyle(palette.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(palette.textTertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("translation_rune_reference_link")
                .listRowSeparator(.hidden)
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
                .font(DesignTokens.Typography.bodyEmphasis)
                .foregroundStyle(palette.textPrimary)
            Text(body)
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(palette.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        TranslationAccuracyContextView()
    }
}
