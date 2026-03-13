//
//  SettingsTypographySectionView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI
import TipKit

struct SettingsTypographySectionView: View {
    let viewModel: SettingsViewModel
    let palette: AppThemePalette
    let tipRefreshID: UUID

    var body: some View {
        SettingsPanel(palette: self.palette) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SettingsSectionHeaderView(title: "Typography", icon: "textformat.size", palette: self.palette)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Font")
                        .font(DesignTokens.Typography.controlLabel)
                        .foregroundStyle(self.palette.textSecondary)

                    GlassFontSelector(
                        selectedFont: Binding(
                            get: { self.viewModel.state.selectedFont },
                            set: { self.viewModel.updateFont($0) },
                        ),
                        availableFonts: self.viewModel.availableFonts,
                    )
                    .accessibilityLabel("Select font style")
                    .accessibilityValue(self.viewModel.state.selectedFont.rawValue)
                    .accessibilityHint("Choose the font used to display runic text")
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("settings_font_section")

                if let error = viewModel.state.errorMessage {
                    Text(error)
                        .font(DesignTokens.Typography.listMeta)
                        .foregroundStyle(self.palette.error)
                        .accessibilityLabel("Error: \(error)")
                }

                Rectangle()
                    .fill(self.palette.separator)
                    .frame(height: 1)

                self.recommendedCombinationsSection
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_typography_section")
    }

    private var recommendedCombinationsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            RunicInlineTip(
                tip: SettingsTypographyPresetTip(),
                palette: self.palette,
                refreshID: self.tipRefreshID,
                accessibilityIdentifier: "tip_settings_typography_preset",
            )

            Text("Recommended Combinations")
                .font(DesignTokens.Typography.controlLabel)
                .foregroundStyle(self.palette.textSecondary)

            ScrollView(.horizontal) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(self.viewModel.recommendedPresets) { preset in
                        self.presetCard(preset)
                    }
                }
                .padding(.vertical, DesignTokens.Spacing.xxs)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func presetCard(_ preset: ReadingPreset) -> some View {
        let isActive = self.viewModel.state.selectedScript == preset.script && self.viewModel.state.selectedFont == preset.font

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                self.viewModel.applyPreset(preset)
            }
            FeatureDiscoveryEvents.settingsAppliedPreset.sendDonation()
            SettingsTypographyPresetTip().invalidate(reason: .actionPerformed)
        } label: {
            self.presetCardBody(preset, isActive: isActive)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("settings_preset_\(preset.rawValue.replacing(" ", with: "_"))")
    }

    private func presetCardBody(_ preset: ReadingPreset, isActive: Bool) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            self.presetCardHeader(preset, isActive: isActive)

            Text("\(preset.script.displayName) + \(preset.font.displayName)")
                .font(DesignTokens.Typography.listMeta)
                .foregroundStyle(self.palette.textTertiary)
                .lineLimit(1)

            Text(self.viewModel.presetPreviewRunicText(for: preset))
                .runicTextStyle(
                    script: preset.script,
                    font: preset.font,
                    style: .body,
                    minSize: 16,
                    maxSize: 24,
                )
                .foregroundStyle(self.palette.runeText)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(preset.previewLatinText)
                .font(DesignTokens.Typography.listMeta)
                .foregroundStyle(self.palette.textSecondary)
                .lineLimit(2)

            Text(preset.description)
                .font(DesignTokens.Typography.listMeta)
                .foregroundStyle(self.palette.textTertiary)
                .lineLimit(2)
        }
        .padding(DesignTokens.Spacing.sm)
        .frame(width: 250, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .fill(isActive ? self.palette.bannerBackground : self.palette.editorialInset)
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                .strokeBorder(
                    isActive ? self.palette.strongCardStroke : self.palette.cardStroke,
                    lineWidth: DesignTokens.Stroke.hairline,
                )
        }
        .shadow(color: self.palette.shadowColor.opacity(isActive ? 0.9 : 0), radius: 4, x: 0, y: 2)
    }

    private func presetCardHeader(_ preset: ReadingPreset, isActive: Bool) -> some View {
        HStack(alignment: .top) {
            Text(preset.displayName)
                .font(DesignTokens.Typography.supportingBody.weight(.semibold))
                .foregroundStyle(self.palette.textPrimary)

            Spacer(minLength: DesignTokens.Spacing.xs)

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(self.palette.accent)
                    .font(.caption)
            }
        }
    }
}
