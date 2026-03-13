//
//  SettingsTypographySectionView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct SettingsTypographySectionView: View {
    let viewModel: SettingsViewModel
    let palette: AppThemePalette

    var body: some View {
        GlassCard(intensity: .medium) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SettingsSectionHeaderView(title: "Typography", icon: "textformat.size", palette: palette)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Font")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textSecondary)

                    GlassFontSelector(
                        selectedFont: Binding(
                            get: { viewModel.state.selectedFont },
                            set: { viewModel.updateFont($0) }
                        ),
                        availableFonts: viewModel.availableFonts
                    )
                    .accessibilityLabel("Select font style")
                    .accessibilityValue(viewModel.state.selectedFont.rawValue)
                    .accessibilityHint("Choose the font used to display runic text")
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("settings_font_section")

                if let error = viewModel.state.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(palette.error)
                        .accessibilityLabel("Error: \(error)")
                }

                Rectangle()
                    .fill(palette.separator)
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Recommended Combinations")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textSecondary)

                    ScrollView(.horizontal) {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ForEach(viewModel.recommendedPresets) { preset in
                                presetCard(preset)
                            }
                        }
                        .padding(.vertical, DesignTokens.Spacing.xxs)
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_typography_section")
    }

    private func presetCard(_ preset: ReadingPreset) -> some View {
        let isActive = viewModel.state.selectedScript == preset.script && viewModel.state.selectedFont == preset.font

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                viewModel.applyPreset(preset)
            }
        } label: {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack(alignment: .top) {
                    Text(preset.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)

                    Spacer(minLength: DesignTokens.Spacing.xs)

                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(palette.accent)
                            .font(.caption)
                    }
                }

                Text("\(preset.script.displayName) + \(preset.font.displayName)")
                    .font(.caption)
                    .foregroundStyle(palette.textTertiary)
                    .lineLimit(1)

                Text(viewModel.presetPreviewRunicText(for: preset))
                    .runicTextStyle(
                        script: preset.script,
                        font: preset.font,
                        style: .body,
                        minSize: 16,
                        maxSize: 24
                    )
                    .foregroundStyle(palette.runeText)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(preset.previewLatinText)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)

                Text(preset.description)
                    .font(.caption)
                    .foregroundStyle(palette.textTertiary)
                    .lineLimit(2)
            }
            .padding(DesignTokens.Spacing.sm)
            .frame(width: 250, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .fill(.ultraThinMaterial)
                    .opacity(isActive ? 0.5 : 0.2)
            }
            .shadow(color: .black.opacity(isActive ? 0.22 : 0), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("settings_preset_\(preset.rawValue.replacing(" ", with: "_"))")
    }
}
