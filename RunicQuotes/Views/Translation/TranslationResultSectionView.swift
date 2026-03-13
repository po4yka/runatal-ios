//
//  TranslationResultSectionView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct TranslationResultSectionView: View {
    let state: TranslationUiState
    let palette: AppThemePalette
    let copyAction: () -> Void
    let clearAction: () -> Void
    let saveAction: () -> Void
    let openSourcesAction: (() -> Void)?

    init(
        state: TranslationUiState,
        palette: AppThemePalette,
        copyAction: @escaping () -> Void,
        clearAction: @escaping () -> Void,
        saveAction: @escaping () -> Void,
        openSourcesAction: (() -> Void)? = nil,
    ) {
        self.state = state
        self.palette = palette
        self.copyAction = copyAction
        self.clearAction = clearAction
        self.saveAction = saveAction
        self.openSourcesAction = openSourcesAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            ContentPlate(
                palette: self.palette,
                tone: .hero,
                cornerRadius: DesignTokens.CornerRadius.xxl,
                shadowRadius: DesignTokens.Elevation.hero,
            ) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    self.header

                    if self.state.outputText.isEmpty {
                        Text("The result will appear here as soon as the source text is ready.")
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(self.palette.textSecondary)
                            .accessibilityIdentifier("translation_output_text")
                    } else {
                        Text(self.state.outputText)
                            .runicTextStyle(
                                script: self.state.selectedScript,
                                font: self.state.selectedFont,
                                style: .title2,
                                minSize: 28,
                                maxSize: 52,
                            )
                            .foregroundStyle(self.palette.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .accessibilityIdentifier("translation_output_text")
                    }

                    if let errorMessage = state.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(self.palette.error)
                    }

                    if let fallbackSuggestion = state.fallbackSuggestion {
                        Text(fallbackSuggestion)
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(self.palette.textSecondary)
                    }

                    if !self.state.userFacingWarnings.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                            ForEach(self.state.userFacingWarnings, id: \.self) { warning in
                                Label(warning, systemImage: "info.circle")
                                    .font(DesignTokens.Typography.metadata)
                                    .foregroundStyle(self.palette.textSecondary)
                            }
                        }
                    }
                }
            }
            .accessibilityIdentifier("translation_output_card")

            LiquidActionCluster(palette: self.palette) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        self.copyButton
                        self.clearButton
                        self.saveButton
                    }

                    VStack(spacing: DesignTokens.Spacing.sm) {
                        self.copyButton
                        self.clearButton
                        self.saveButton
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    SectionLabel(title: "Output", palette: self.palette)

                    Text("Runic result")
                        .font(DesignTokens.Typography.sectionTitle)
                        .foregroundStyle(self.palette.textPrimary)
                }

                Spacer()

                if let resolutionStatus = state.resolutionStatus {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        self.statusBadge(resolutionStatus.displayName)
                        if let evidenceTier = state.evidenceTier {
                            self.statusBadge(evidenceTier.displayName)
                        }
                        if let supportLevel = state.supportLevel {
                            self.statusBadge(supportLevel.displayName)
                        }
                    }
                }
            }

            MetaRow(items: self.outputMeta, palette: self.palette)

            if let primarySourceLabel = state.primarySourceLabel {
                HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text("Primary source")
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(self.palette.textTertiary)
                        Text(primarySourceLabel)
                            .font(DesignTokens.Typography.bodyEmphasis)
                            .foregroundStyle(self.palette.textPrimary)
                        if let detail = state.primarySourceDetail {
                            Text(detail)
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(self.palette.textSecondary)
                        }
                    }

                    Spacer()

                    if let openSourcesAction {
                        Button("Sources", action: openSourcesAction)
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(self.palette.accent)
                    }
                }
            }
        }
    }

    private var outputMeta: [String] {
        var items = [state.selectedScript.displayName]
        items.append(self.state.translationMode == .translate ? self.state.selectedFidelity.displayName : "Direct transliteration")
        if let derivationKind = state.derivationKind {
            items.append(derivationKind.displayName)
        }
        return items
    }

    private var copyButton: some View {
        Button(action: self.copyAction) {
            Label("Copy", systemImage: "doc.on.doc")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidProminentButtonStyle(palette: self.palette, emphasized: false))
        .disabled(self.state.outputText.isEmpty)
        .accessibilityIdentifier("translation_copy_button")
    }

    private var clearButton: some View {
        Button(action: self.clearAction) {
            Label("Clear", systemImage: "xmark.circle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidProminentButtonStyle(palette: self.palette, emphasized: false))
        .accessibilityIdentifier("translation_clear_button")
    }

    private var saveButton: some View {
        Button(action: self.saveAction) {
            Label(self.saveTitle, systemImage: "square.and.arrow.down")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidProminentButtonStyle(palette: self.palette, emphasized: true))
        .disabled(self.state.isInputEmpty || self.state.isSaving)
        .accessibilityIdentifier("translation_save_button")
    }

    private var saveTitle: String {
        self.state.translationMode == .translate ? "Save Translation" : "Save"
    }

    private func statusBadge(_ title: String) -> some View {
        Text(title)
            .font(DesignTokens.Typography.metadata)
            .foregroundStyle(self.palette.subtleAccentText)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(
                Capsule(style: .continuous)
                    .fill(self.palette.rowInsetFill),
            )
    }
}
