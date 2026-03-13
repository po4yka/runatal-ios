//
//  TranslationSupplementarySectionsView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct TranslationSupplementarySectionsView: View {
    let state: TranslationUiState
    let palette: AppThemePalette

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            if state.translationMode == .translate,
               state.normalizedForm != nil || state.diplomaticForm != nil {
                layersCard
            }

            if state.translationMode == .translate,
               !state.notes.isEmpty || !state.unresolvedTokens.isEmpty || state.derivationKind != nil {
                notesCard
            }

            if state.translationMode == .translate, !state.provenance.isEmpty {
                provenanceCard
            }

            if state.isWordByWordEnabled, !state.tokenBreakdown.isEmpty {
                breakdownCard
            }
        }
    }

    private var layersCard: some View {
        ContentPlate(
            palette: palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.low
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SectionLabel(title: "Layers", palette: palette)

                Text("Language layers")
                    .font(DesignTokens.Typography.sectionTitle)
                    .foregroundStyle(palette.textPrimary)

                if let normalized = state.normalizedForm {
                    labelValueRow(title: "Normalized", value: normalized)
                }

                if let diplomatic = state.diplomaticForm {
                    labelValueRow(title: "Diplomatic", value: diplomatic)
                }
            }
        }
    }

    private var notesCard: some View {
        ContentPlate(
            palette: palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.low
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SectionLabel(title: "Notes", palette: palette)

                if let derivationKind = state.derivationKind {
                    labelValueRow(title: "Derivation", value: derivationKind.displayName)
                }

                if !state.notes.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Reading notes")
                            .font(DesignTokens.Typography.bodyEmphasis)
                            .foregroundStyle(palette.textPrimary)

                        ForEach(state.notes, id: \.self) { note in
                            Text(note)
                                .font(DesignTokens.Typography.callout)
                                .foregroundStyle(palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if !state.unresolvedTokens.isEmpty {
                    labelValueRow(
                        title: "Unresolved tokens",
                        value: state.unresolvedTokens.joined(separator: ", ")
                    )
                }
            }
        }
    }

    private var provenanceCard: some View {
        ContentPlate(
            palette: palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.low
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SectionLabel(title: "Evidence", palette: palette)

                Text("Provenance")
                    .font(DesignTokens.Typography.sectionTitle)
                    .foregroundStyle(palette.textPrimary)

                ForEach(Array(state.provenance.enumerated()), id: \.offset) { index, entry in
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                                Text(entry.label)
                                    .font(DesignTokens.Typography.bodyEmphasis)
                                    .foregroundStyle(palette.textPrimary)

                                Text(entry.role)
                                    .font(DesignTokens.Typography.metadata)
                                    .foregroundStyle(palette.textSecondary)
                            }

                            Spacer()

                            Text(entry.license)
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(palette.textTertiary)
                        }

                        if let detail = entry.detail {
                            Text(detail)
                                .font(DesignTokens.Typography.callout)
                                .foregroundStyle(palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let url = entry.url, let resolvedURL = URL(string: url) {
                            Link(destination: resolvedURL) {
                                Text(url)
                                    .font(DesignTokens.Typography.metadata)
                                    .foregroundStyle(palette.accent)
                                    .lineLimit(1)
                            }
                        }

                        if index < state.provenance.count - 1 {
                            Divider()
                                .overlay(palette.contentStroke.opacity(0.6))
                        }
                    }
                }
            }
        }
    }

    private var breakdownCard: some View {
        ContentPlate(
            palette: palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.low
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SectionLabel(title: "Breakdown", palette: palette)

                Text(state.translationMode == .translate ? "Token breakdown" : "Character breakdown")
                    .font(DesignTokens.Typography.sectionTitle)
                    .foregroundStyle(palette.textPrimary)

                ForEach(Array(state.tokenBreakdown.enumerated()), id: \.element.id) { index, token in
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                                Text(token.sourceToken)
                                    .font(DesignTokens.Typography.bodyEmphasis)
                                    .foregroundStyle(palette.textPrimary)

                                if state.translationMode == .translate {
                                    Text(token.resolutionStatus.displayName)
                                        .font(DesignTokens.Typography.metadata)
                                        .foregroundStyle(palette.textTertiary)
                                }
                            }

                            Spacer()

                            Text(token.glyphToken)
                                .runicTextStyle(
                                    script: state.selectedScript,
                                    font: state.selectedFont,
                                    style: .title3,
                                    minSize: 20,
                                    maxSize: 40
                                )
                                .foregroundStyle(palette.textPrimary)
                        }

                        if state.translationMode == .translate {
                            Text("Normalized: \(token.normalizedToken)")
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(palette.textSecondary)

                            Text("Diplomatic: \(token.diplomaticToken)")
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(palette.textSecondary)
                        }

                        if index < state.tokenBreakdown.count - 1 {
                            Divider()
                                .overlay(palette.contentStroke.opacity(0.6))
                        }
                    }
                }
            }
        }
    }

    private func labelValueRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Text(title)
                .font(DesignTokens.Typography.bodyEmphasis)
                .foregroundStyle(palette.textPrimary)

            Text(value)
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(palette.textSecondary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
