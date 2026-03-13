//
//  SettingsAppearanceSectionView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct SettingsAppearanceSectionView: View {
    let viewModel: SettingsViewModel
    let palette: AppThemePalette

    var body: some View {
        SettingsPanel(palette: self.palette) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SettingsSectionHeaderView(title: "Appearance", icon: "paintbrush", palette: self.palette)

                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(AppTheme.allCases) { theme in
                        self.themeButton(theme)

                        if theme != AppTheme.allCases.last {
                            Rectangle()
                                .fill(self.palette.separator)
                                .frame(height: 1)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    self.actionRow(
                        icon: "arrow.counterclockwise",
                        title: "Reset to Defaults",
                        isEnabled: !self.viewModel.isAtDefaults,
                    ) {
                        Haptics.trigger(.saveOrShare)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.viewModel.resetToDefaults()
                        }
                    }
                    .accessibilityIdentifier("settings_reset_defaults_button")

                    self.actionRow(
                        icon: "wand.and.stars",
                        title: "Restore Last Preset",
                        isEnabled: self.viewModel.canRestoreLastPreset,
                    ) {
                        Haptics.trigger(.saveOrShare)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.viewModel.restoreLastUsedPreset()
                        }
                    }
                    .accessibilityIdentifier("settings_restore_preset_button")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_appearance_section")
    }

    private func themeButton(_ theme: AppTheme) -> some View {
        let themePalette = AppThemePalette.themed(theme, for: .dark)
        let isSelected = self.viewModel.state.selectedTheme == theme

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.viewModel.updateTheme(theme)
            }
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                HStack(spacing: DesignTokens.Spacing.xxs) {
                    Circle().fill(themePalette.appBackgroundGradient.first ?? .black)
                    Circle().fill(themePalette.appBackgroundGradient.dropFirst().first ?? .gray)
                    Circle().fill(themePalette.appBackgroundGradient.last ?? .white)
                }
                .frame(width: 48, height: 12)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    Text(theme.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(self.palette.textPrimary)

                    Text(theme.description)
                        .font(DesignTokens.Typography.listMeta)
                        .foregroundStyle(self.palette.textTertiary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(self.palette.accent)
                        .font(.title3)
                        .accessibilityLabel("Selected")
                }
            }
            .padding(.vertical, DesignTokens.Spacing.xxs)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(theme.displayName) theme")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Double tap to select the \(theme.displayName) theme")
        .accessibilityIdentifier("settings_theme_\(theme.rawValue.replacing(" ", with: "_"))")
    }

    private func actionRow(
        icon: String,
        title: String,
        isEnabled: Bool,
        action: @escaping () -> Void,
    ) -> some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                Text(title)
            }
            .font(DesignTokens.Typography.controlLabel)
            .foregroundStyle(self.palette.textPrimary.opacity(isEnabled ? 0.92 : 0.3))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                    .fill(isEnabled ? self.palette.bannerBackground : self.palette.editorialMutedSurface)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
