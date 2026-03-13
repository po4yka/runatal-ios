//
//  TranslationComposerSectionView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct TranslationComposerSectionView: View {
    let state: TranslationUiState
    let palette: AppThemePalette
    let tipRefreshID: UUID
    let modeBinding: Binding<TranslationMode>
    let fidelityBinding: Binding<TranslationFidelity>
    let youngerVariantBinding: Binding<YoungerFutharkVariant>
    let inputBinding: Binding<String>
    let wordByWordBinding: Binding<Bool>
    let isInputFocused: FocusState<Bool>.Binding
    let selectScript: (RunicScript) -> Void
    let openSourcesAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            LiquidCard(
                palette: self.palette,
                role: .chrome,
                cornerRadius: DesignTokens.CornerRadius.xxl,
                contentPadding: DesignTokens.Spacing.md,
                interactive: true,
            ) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    SectionLabel(title: "Method", palette: self.palette)

                    Picker("Mode", selection: self.modeBinding) {
                        ForEach(TranslationMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if self.state.translationMode == .translate {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("Fidelity")
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(self.palette.textTertiary)

                            Picker("Fidelity", selection: self.fidelityBinding) {
                                ForEach(TranslationFidelity.allCases) { fidelity in
                                    Text(fidelity.displayName).tag(fidelity)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        if self.state.selectedScript == .younger {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                Text("Variant")
                                    .font(DesignTokens.Typography.metadata)
                                    .foregroundStyle(self.palette.textTertiary)

                                Picker("Variant", selection: self.youngerVariantBinding) {
                                    ForEach(YoungerFutharkVariant.allCases) { variant in
                                        Text(variant.displayName).tag(variant)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }
                    }
                }
            }

            RunicInlineTip(
                tip: TranslationMethodTip(),
                palette: self.palette,
                refreshID: self.tipRefreshID,
                accessibilityIdentifier: "tip_translation_method",
            )

            GlassScriptSelector(
                selectedScript: Binding(
                    get: { self.state.selectedScript },
                    set: { self.selectScript($0) },
                ),
            )
            .accessibilityIdentifier("translation_script_selector")

            ContentPlate(
                palette: self.palette,
                tone: .primary,
                cornerRadius: DesignTokens.CornerRadius.xxl,
                shadowRadius: DesignTokens.Elevation.medium,
            ) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    SectionLabel(title: "Source", palette: self.palette)

                    Text("Source text")
                        .font(DesignTokens.Typography.sectionTitle)
                        .foregroundStyle(self.palette.textPrimary)

                    if let sourceLanguageBanner = state.sourceLanguageBanner {
                        HStack(alignment: .center, spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "textformat.abc")
                                .foregroundStyle(self.palette.textSecondary)
                            Text(sourceLanguageBanner)
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(self.palette.textSecondary)
                                .accessibilityIdentifier("translation_source_language_banner")
                        }
                        .accessibilityElement(children: .combine)
                    }

                    if self.state.translationMode == .translate {
                        self.translationSupportSummary
                    }

                    ZStack(alignment: .topLeading) {
                        if self.state.inputText.isEmpty {
                            Text("Enter up to 280 characters to explore a direct transliteration or a historically constrained rendering.")
                                .font(DesignTokens.Typography.callout)
                                .foregroundStyle(self.palette.textTertiary)
                                .padding(.top, DesignTokens.Spacing.sm)
                                .padding(.horizontal, DesignTokens.Spacing.sm)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: self.inputBinding)
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(self.palette.textPrimary)
                            .focused(self.isInputFocused)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 176)
                            .padding(DesignTokens.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous)
                                    .fill(self.palette.fieldFill),
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous)
                                    .strokeBorder(self.palette.contentStroke, lineWidth: DesignTokens.Stroke.hairline),
                            )
                            .accessibilityIdentifier("translation_input_editor")
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .center, spacing: DesignTokens.Spacing.md) {
                            self.breakdownToggle
                            Spacer(minLength: DesignTokens.Spacing.md)
                            self.characterCount
                        }

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            self.breakdownToggle
                            self.characterCount
                        }
                    }
                }
            }
        }
    }

    private var breakdownToggle: some View {
        Toggle(isOn: self.wordByWordBinding) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(self.state.translationMode == .translate ? "Word by word breakdown" : "Character breakdown")
                    .font(DesignTokens.Typography.bodyEmphasis)
                    .foregroundStyle(self.palette.textPrimary)

                Text("Expose the intermediate reading path below the result.")
                    .font(DesignTokens.Typography.metadata)
                    .foregroundStyle(self.palette.textSecondary)
            }
        }
        .tint(self.palette.accent)
        .accessibilityIdentifier("translation_word_by_word_button")
    }

    private var characterCount: some View {
        Text("\(self.state.remainingCharacters) characters left")
            .font(DesignTokens.Typography.metadata)
            .foregroundStyle(self.palette.textTertiary)
    }

    private var translationSupportSummary: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                if let evidenceTier = state.evidenceTier {
                    self.compactBadge(evidenceTier.displayName)
                        .accessibilityIdentifier("translation_evidence_badge")
                }

                if let supportLevel = state.supportLevel {
                    self.compactBadge(supportLevel.displayName)
                        .accessibilityIdentifier("translation_support_badge")
                }
            }

            if let primarySourceLabel = state.primarySourceLabel {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                            Text("Primary source")
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(self.palette.textTertiary)

                            Text(primarySourceLabel)
                                .font(DesignTokens.Typography.bodyEmphasis)
                                .foregroundStyle(self.palette.textPrimary)
                                .accessibilityIdentifier("translation_primary_source_label")
                        }

                        Spacer()

                        if let openSourcesAction {
                            Button("Sources", action: openSourcesAction)
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(self.palette.accent)
                                .accessibilityIdentifier("translation_sources_button")
                        }
                    }

                    if let primarySourceDetail = state.primarySourceDetail {
                        Text(primarySourceDetail)
                            .font(DesignTokens.Typography.metadata)
                            .foregroundStyle(self.palette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func compactBadge(_ title: String) -> some View {
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
