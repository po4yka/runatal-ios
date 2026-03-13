//
//  SettingsAboutSectionView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct SettingsAboutSectionView: View {
    let palette: AppThemePalette
    let showTipsAgain: () -> Void

    var body: some View {
        SettingsPanel(palette: self.palette) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SettingsSectionHeaderView(title: "About", icon: "info.circle", palette: self.palette)

                VStack(spacing: DesignTokens.Spacing.sm) {
                    self.aboutRow("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")

                    Rectangle()
                        .fill(self.palette.separator)
                        .frame(height: 1)

                    self.aboutRow("Scripts", value: "\(RunicScript.allCases.count)")

                    Rectangle()
                        .fill(self.palette.separator)
                        .frame(height: 1)

                    self.aboutRow("Fonts", value: "\(RunicFont.allCases.count)")

                    Rectangle()
                        .fill(self.palette.separator)
                        .frame(height: 1)

                    HStack {
                        Text("Rate on App Store")
                            .font(DesignTokens.Typography.supportingBody.weight(.medium))
                            .foregroundStyle(self.palette.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(self.palette.textTertiary)
                    }
                    .padding(.vertical, DesignTokens.Spacing.xxs)

                    Rectangle()
                        .fill(self.palette.separator)
                        .frame(height: 1)

                    Button(action: self.showTipsAgain) {
                        HStack {
                            Text("Show Tips Again")
                                .font(DesignTokens.Typography.supportingBody.weight(.medium))
                                .foregroundStyle(self.palette.textPrimary)

                            Spacer()

                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(self.palette.accent)
                        }
                        .padding(.vertical, DesignTokens.Spacing.xxs)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("settings_show_tips_again_button")
                }

                Text("Bringing ancient wisdom to modern devices")
                    .font(DesignTokens.Typography.listMeta)
                    .foregroundStyle(self.palette.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_about_section")
    }

    private func aboutRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(DesignTokens.Typography.supportingBody.weight(.medium))
                .foregroundStyle(self.palette.textPrimary)

            Spacer()

            Text(value)
                .font(DesignTokens.Typography.supportingBody)
                .foregroundStyle(self.palette.textSecondary)
        }
        .padding(.vertical, DesignTokens.Spacing.xxs)
    }
}
