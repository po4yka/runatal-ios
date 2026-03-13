//
//  TranslationSupplementarySectionsView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct TranslationSupplementarySectionsView: View {
    let state: TranslationUiState
    let palette: AppThemePalette

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            if self.state.translationMode == .translate,
               self.state.normalizedForm != nil || self.state.diplomaticForm != nil
            {
                self.layersCard
            }

            if self.state.translationMode == .translate,
               !self.state.notes.isEmpty ||
               !self.state.unresolvedTokens.isEmpty ||
               self.state.derivationKind != nil ||
               self.state.supportLevel != nil ||
               self.state.evidenceTier != nil ||
               !self.state.attestationRefs.isEmpty ||
               !self.state.userFacingWarnings.isEmpty
            {
                self.notesCard
            }

            if self.state.translationMode == .translate, !self.state.provenance.isEmpty {
                self.provenanceCard
            }

            if self.state.isWordByWordEnabled, !self.state.tokenBreakdown.isEmpty {
                self.breakdownCard
            }
        }
    }

    private var layersCard: some View {
        ContentPlate(
            palette: self.palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.low,
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SectionLabel(title: "Layers", palette: self.palette)

                Text("Language layers")
                    .font(DesignTokens.Typography.sectionTitle)
                    .foregroundStyle(self.palette.textPrimary)

                if let normalized = state.normalizedForm {
                    self.labelValueRow(title: "Normalized", value: normalized)
                }

                if let diplomatic = state.diplomaticForm {
                    self.labelValueRow(title: "Diplomatic", value: diplomatic)
                }
            }
        }
    }

    private var notesCard: some View {
        ContentPlate(
            palette: self.palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.low,
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SectionLabel(title: "Notes", palette: self.palette)

                if let derivationKind = state.derivationKind {
                    self.labelValueRow(title: "Derivation", value: derivationKind.displayName)
                }

                if let supportLevel = state.supportLevel {
                    self.labelValueRow(title: "Support", value: supportLevel.displayName)
                }

                if let evidenceTier = state.evidenceTier {
                    self.labelValueRow(title: "Evidence", value: evidenceTier.displayName)
                }

                if !self.state.notes.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Reading notes")
                            .font(DesignTokens.Typography.bodyEmphasis)
                            .foregroundStyle(self.palette.textPrimary)

                        ForEach(self.state.notes, id: \.self) { note in
                            Text(note)
                                .font(DesignTokens.Typography.callout)
                                .foregroundStyle(self.palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                if !self.state.unresolvedTokens.isEmpty {
                    self.labelValueRow(
                        title: "Unresolved tokens",
                        value: self.state.unresolvedTokens.joined(separator: ", "),
                    )
                }

                if !self.state.attestationRefs.isEmpty {
                    self.labelValueRow(
                        title: "Attestation refs",
                        value: self.state.attestationRefs.joined(separator: ", "),
                    )
                }

                if !self.state.userFacingWarnings.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Support notes")
                            .font(DesignTokens.Typography.bodyEmphasis)
                            .foregroundStyle(self.palette.textPrimary)

                        ForEach(self.state.userFacingWarnings, id: \.self) { warning in
                            Text(warning)
                                .font(DesignTokens.Typography.callout)
                                .foregroundStyle(self.palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var provenanceCard: some View {
        ContentPlate(
            palette: self.palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.low,
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SectionLabel(title: "Evidence", palette: self.palette)

                Text("Provenance")
                    .font(DesignTokens.Typography.sectionTitle)
                    .foregroundStyle(self.palette.textPrimary)

                ForEach(Array(self.state.provenance.enumerated()), id: \.offset) { index, entry in
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                                Text(entry.label)
                                    .font(DesignTokens.Typography.bodyEmphasis)
                                    .foregroundStyle(self.palette.textPrimary)

                                Text(entry.role)
                                    .font(DesignTokens.Typography.metadata)
                                    .foregroundStyle(self.palette.textSecondary)
                            }

                            Spacer()

                            Text(entry.license)
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(self.palette.textTertiary)
                        }

                        if let detail = entry.detail {
                            Text(detail)
                                .font(DesignTokens.Typography.callout)
                                .foregroundStyle(self.palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let url = entry.url, let resolvedURL = URL(string: url) {
                            Link(destination: resolvedURL) {
                                Text(url)
                                    .font(DesignTokens.Typography.metadata)
                                    .foregroundStyle(self.palette.accent)
                                    .lineLimit(1)
                            }
                        }

                        if index < self.state.provenance.count - 1 {
                            Divider()
                                .overlay(self.palette.contentStroke.opacity(0.6))
                        }
                    }
                }
            }
        }
    }

    private var breakdownCard: some View {
        ContentPlate(
            palette: self.palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xxl,
            shadowRadius: DesignTokens.Elevation.low,
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SectionLabel(title: "Breakdown", palette: self.palette)

                Text(self.state.translationMode == .translate ? "Token breakdown" : "Character breakdown")
                    .font(DesignTokens.Typography.sectionTitle)
                    .foregroundStyle(self.palette.textPrimary)

                ForEach(Array(self.state.tokenBreakdown.enumerated()), id: \.element.id) { index, token in
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                                Text(token.sourceToken)
                                    .font(DesignTokens.Typography.bodyEmphasis)
                                    .foregroundStyle(self.palette.textPrimary)

                                if self.state.translationMode == .translate {
                                    Text(token.resolutionStatus.displayName)
                                        .font(DesignTokens.Typography.metadata)
                                        .foregroundStyle(self.palette.textTertiary)
                                }
                            }

                            Spacer()

                            Text(token.glyphToken)
                                .runicTextStyle(
                                    script: self.state.selectedScript,
                                    font: self.state.selectedFont,
                                    style: .title3,
                                    minSize: 20,
                                    maxSize: 40,
                                )
                                .foregroundStyle(self.palette.textPrimary)
                        }

                        if self.state.translationMode == .translate {
                            Text("Normalized: \(token.normalizedToken)")
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(self.palette.textSecondary)

                            Text("Diplomatic: \(token.diplomaticToken)")
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(self.palette.textSecondary)
                        }

                        if index < self.state.tokenBreakdown.count - 1 {
                            Divider()
                                .overlay(self.palette.contentStroke.opacity(0.6))
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
                .foregroundStyle(self.palette.textPrimary)

            Text(value)
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(self.palette.textSecondary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
