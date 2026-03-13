//
//  TranslationComposerSectionView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct TranslationComposerSectionView: View {
    let state: TranslationUiState
    let palette: AppThemePalette
    let modeBinding: Binding<TranslationMode>
    let fidelityBinding: Binding<TranslationFidelity>
    let youngerVariantBinding: Binding<YoungerFutharkVariant>
    let inputBinding: Binding<String>
    let wordByWordBinding: Binding<Bool>
    let selectScript: (RunicScript) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            LiquidCard(
                palette: palette,
                role: .chrome,
                cornerRadius: DesignTokens.CornerRadius.xxl,
                contentPadding: DesignTokens.Spacing.md,
                interactive: true
            ) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    SectionLabel(title: "Method", palette: palette)

                    Picker("Mode", selection: modeBinding) {
                        ForEach(TranslationMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if state.translationMode == .translate {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("Fidelity")
                                .font(DesignTokens.Typography.metadata)
                                .foregroundStyle(palette.textTertiary)

                            Picker("Fidelity", selection: fidelityBinding) {
                                ForEach(TranslationFidelity.allCases) { fidelity in
                                    Text(fidelity.displayName).tag(fidelity)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        if state.selectedScript == .younger {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                Text("Variant")
                                    .font(DesignTokens.Typography.metadata)
                                    .foregroundStyle(palette.textTertiary)

                                Picker("Variant", selection: youngerVariantBinding) {
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

            GlassScriptSelector(
                selectedScript: Binding(
                    get: { state.selectedScript },
                    set: { selectScript($0) }
                )
            )
            .accessibilityIdentifier("translation_script_selector")

            ContentPlate(
                palette: palette,
                tone: .primary,
                cornerRadius: DesignTokens.CornerRadius.xxl,
                shadowRadius: DesignTokens.Elevation.medium
            ) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    SectionLabel(title: "Source", palette: palette)

                    Text("Source text")
                        .font(DesignTokens.Typography.sectionTitle)
                        .foregroundStyle(palette.textPrimary)

                    ZStack(alignment: .topLeading) {
                        if state.inputText.isEmpty {
                            Text("Enter up to 280 characters to explore a direct transliteration or a historically constrained rendering.")
                                .font(DesignTokens.Typography.callout)
                                .foregroundStyle(palette.textTertiary)
                                .padding(.top, DesignTokens.Spacing.sm)
                                .padding(.horizontal, DesignTokens.Spacing.sm)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: inputBinding)
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(palette.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 176)
                            .padding(DesignTokens.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous)
                                    .fill(palette.fieldFill)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous)
                                    .strokeBorder(palette.contentStroke, lineWidth: DesignTokens.Stroke.hairline)
                            )
                            .accessibilityIdentifier("translation_input_editor")
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .center, spacing: DesignTokens.Spacing.md) {
                            breakdownToggle
                            Spacer(minLength: DesignTokens.Spacing.md)
                            characterCount
                        }

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            breakdownToggle
                            characterCount
                        }
                    }
                }
            }
        }
    }

    private var breakdownToggle: some View {
        Toggle(isOn: wordByWordBinding) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(state.translationMode == .translate ? "Word by word breakdown" : "Character breakdown")
                    .font(DesignTokens.Typography.bodyEmphasis)
                    .foregroundStyle(palette.textPrimary)

                Text("Expose the intermediate reading path below the result.")
                    .font(DesignTokens.Typography.metadata)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .tint(palette.accent)
        .accessibilityIdentifier("translation_word_by_word_button")
    }

    private var characterCount: some View {
        Text("\(state.remainingCharacters) characters left")
            .font(DesignTokens.Typography.metadata)
            .foregroundStyle(palette.textTertiary)
    }
}
