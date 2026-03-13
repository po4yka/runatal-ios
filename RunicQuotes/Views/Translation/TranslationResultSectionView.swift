//
//  TranslationResultSectionView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct TranslationResultSectionView: View {
    let state: TranslationUiState
    let palette: AppThemePalette
    let copyAction: () -> Void
    let clearAction: () -> Void
    let saveAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            ContentPlate(
                palette: palette,
                tone: .hero,
                cornerRadius: DesignTokens.CornerRadius.xxl,
                shadowRadius: DesignTokens.Elevation.hero
            ) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    header

                    if state.outputText.isEmpty {
                        Text("The result will appear here as soon as the source text is ready.")
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(palette.textSecondary)
                            .accessibilityIdentifier("translation_output_text")
                    } else {
                        Text(state.outputText)
                            .runicTextStyle(
                                script: state.selectedScript,
                                font: state.selectedFont,
                                style: .title2,
                                minSize: 28,
                                maxSize: 52
                            )
                            .foregroundStyle(palette.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .accessibilityIdentifier("translation_output_text")
                    }

                    if let errorMessage = state.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(palette.error)
                    }

                    if let fallbackSuggestion = state.fallbackSuggestion {
                        Text(fallbackSuggestion)
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(palette.textSecondary)
                    }
                }
            }
            .accessibilityIdentifier("translation_output_card")

            LiquidActionCluster(palette: palette) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        copyButton
                        clearButton
                        saveButton
                    }

                    VStack(spacing: DesignTokens.Spacing.sm) {
                        copyButton
                        clearButton
                        saveButton
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    SectionLabel(title: "Output", palette: palette)

                    Text("Runic result")
                        .font(DesignTokens.Typography.sectionTitle)
                        .foregroundStyle(palette.textPrimary)
                }

                Spacer()

                if let resolutionStatus = state.resolutionStatus {
                    Text(resolutionStatus.displayName)
                        .font(DesignTokens.Typography.metadata)
                        .foregroundStyle(palette.subtleAccentText)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background(
                            Capsule(style: .continuous)
                                .fill(palette.rowInsetFill)
                        )
                }
            }

            MetaRow(items: outputMeta, palette: palette)
        }
    }

    private var outputMeta: [String] {
        var items = [state.selectedScript.displayName]
        items.append(state.translationMode == .translate ? state.selectedFidelity.displayName : "Direct transliteration")
        if let derivationKind = state.derivationKind {
            items.append(derivationKind.displayName)
        }
        return items
    }

    private var copyButton: some View {
        Button(action: copyAction) {
            Label("Copy", systemImage: "doc.on.doc")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidProminentButtonStyle(palette: palette, emphasized: false))
        .disabled(state.outputText.isEmpty)
        .accessibilityIdentifier("translation_copy_button")
    }

    private var clearButton: some View {
        Button(action: clearAction) {
            Label("Clear", systemImage: "xmark.circle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidProminentButtonStyle(palette: palette, emphasized: false))
        .accessibilityIdentifier("translation_clear_button")
    }

    private var saveButton: some View {
        Button(action: saveAction) {
            Label(saveTitle, systemImage: "square.and.arrow.down")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidProminentButtonStyle(palette: palette, emphasized: true))
        .disabled(state.isInputEmpty || state.isSaving)
        .accessibilityIdentifier("translation_save_button")
    }

    private var saveTitle: String {
        state.translationMode == .translate ? "Save Translation" : "Save"
    }
}
