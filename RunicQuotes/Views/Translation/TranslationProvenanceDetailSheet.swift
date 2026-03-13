//
//  TranslationProvenanceDetailSheet.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct TranslationProvenanceDetailSheet: View {
    let provenance: [TranslationProvenanceEntry]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.runicTheme) private var runicTheme

    var body: some View {
        NavigationStack {
            LiquidListScaffold(palette: palette) {
                if provenance.isEmpty {
                    Section {
                        EditorialEmptyState(
                            palette: palette,
                            icon: "books.vertical",
                            eyebrow: "Reference",
                            title: "No sources available",
                            message: "This result does not have bundled provenance metadata yet."
                        )
                        .listRowSeparator(.hidden)
                    }
                } else {
                    Section {
                        ForEach(Array(provenance.enumerated()), id: \.offset) { _, entry in
                            ContentPlate(
                                palette: palette,
                                tone: .secondary,
                                cornerRadius: DesignTokens.CornerRadius.xxl,
                                shadowRadius: DesignTokens.Elevation.low
                            ) {
                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                    SectionLabel(title: entry.role, palette: palette)

                                    Text(entry.label)
                                        .font(DesignTokens.Typography.sectionTitle)
                                        .foregroundStyle(palette.textPrimary)

                                    if let sourceWork = entry.sourceWork {
                                        Text(sourceWork)
                                            .font(DesignTokens.Typography.bodyEmphasis)
                                            .foregroundStyle(palette.textPrimary)
                                    }

                                    if let detail = entry.detail {
                                        Text(detail)
                                            .font(DesignTokens.Typography.callout)
                                            .foregroundStyle(palette.textSecondary)
                                    }

                                    metadataRows(for: entry)
                                }
                            }
                            .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .navigationTitle("Sources")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var palette: AppThemePalette {
        .themed(runicTheme, for: colorScheme)
    }

    @ViewBuilder
    private func metadataRows(for entry: TranslationProvenanceEntry) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            metadataRow(title: "Source ID", value: entry.sourceID)
            if let referenceID = entry.referenceID {
                metadataRow(title: "Reference", value: referenceID)
            }
            if let attestationStatus = entry.attestationStatus?.rawValue {
                metadataRow(title: "Attestation", value: attestationStatus.replacingOccurrences(of: "_", with: " "))
            }
            if let grammaticalClass = entry.grammaticalClass {
                metadataRow(title: "Grammar", value: grammaticalClass)
            }
            if let historicalStage = entry.historicalStage {
                metadataRow(title: "Stage", value: historicalStage)
            }
            if let lemmaAuthorityID = entry.lemmaAuthorityID {
                metadataRow(title: "Lemma ID", value: lemmaAuthorityID)
            }
            if let regressionID = entry.regressionID {
                metadataRow(title: "Regression", value: regressionID)
            }
            if let licenseNote = entry.licenseNote {
                metadataRow(title: "License note", value: licenseNote)
            } else {
                metadataRow(title: "License", value: entry.license)
            }
            if let url = entry.url {
                metadataRow(title: "URL", value: url)
            }
        }
    }

    private func metadataRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Text(title)
                .font(DesignTokens.Typography.metadata)
                .foregroundStyle(palette.textTertiary)
            Text(value)
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(palette.textSecondary)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    TranslationProvenanceDetailSheet(
        provenance: [
            TranslationProvenanceEntry(
                sourceID: "zoega-1910",
                referenceID: "entry-1",
                label: "Zoega Old Icelandic Dictionary",
                role: "Lexicon",
                license: "Public domain",
                sourceWork: "A Concise Dictionary of Old Icelandic",
                licenseNote: nil,
                attestationStatus: .attested,
                lemmaAuthorityID: "zoega-1",
                grammaticalClass: "noun",
                historicalStage: "Old Norse",
                regressionID: nil,
                detail: "Bundled lexical source used for the selected term.",
                url: "https://example.com"
            )
        ]
    )
}
