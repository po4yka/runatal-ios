//
//  SettingsAboutSectionView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct SettingsAboutSectionView: View {
    let palette: AppThemePalette

    var body: some View {
        GlassCard(intensity: .medium) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SettingsSectionHeaderView(title: "About", icon: "info.circle", palette: palette)

                VStack(spacing: DesignTokens.Spacing.sm) {
                    aboutRow("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")

                    Rectangle()
                        .fill(palette.separator)
                        .frame(height: 1)

                    aboutRow("Scripts", value: "\(RunicScript.allCases.count)")

                    Rectangle()
                        .fill(palette.separator)
                        .frame(height: 1)

                    aboutRow("Fonts", value: "\(RunicFont.allCases.count)")

                    Rectangle()
                        .fill(palette.separator)
                        .frame(height: 1)

                    HStack {
                        Text("Rate on App Store")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(palette.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(palette.textTertiary)
                    }
                    .padding(.vertical, DesignTokens.Spacing.xxs)
                }

                Text("Bringing ancient wisdom to modern devices")
                    .font(.caption)
                    .foregroundStyle(palette.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_about_section")
    }

    private func aboutRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(palette.textPrimary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
        }
        .padding(.vertical, DesignTokens.Spacing.xxs)
    }
}
