//
//  SettingsAccessibilitySectionView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SettingsAccessibilitySectionView: View {
    let palette: AppThemePalette
    let reduceTransparency: Bool
    let reduceMotion: Bool
    @Environment(\.openURL) private var openURL

    var body: some View {
        GlassCard(intensity: .medium) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SettingsSectionHeaderView(title: "Accessibility", icon: "accessibility", palette: palette)

                statusRow(
                    title: "Reduce Transparency",
                    subtitle: "Replaces glass effects with solid backgrounds",
                    isEnabled: reduceTransparency
                )

                Rectangle()
                    .fill(palette.separator)
                    .frame(height: 1)

                statusRow(
                    title: "Reduce Motion",
                    subtitle: "Minimizes animations throughout the app",
                    isEnabled: reduceMotion
                )

                Rectangle()
                    .fill(palette.separator)
                    .frame(height: 1)

                if let systemSettingsURL {
                    Button {
                        openURL(systemSettingsURL)
                    } label: {
                        HStack {
                            Text("Open System Settings")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(palette.accent)

                            Spacer()

                            Image(systemName: "arrow.up.forward.app")
                                .font(.caption)
                                .foregroundStyle(palette.textTertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_accessibility_section")
    }

    private func statusRow(title: String, subtitle: String, isEnabled: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(palette.textTertiary)
            }

            Spacer()

            Text(isEnabled ? "On" : "Off")
                .font(.subheadline)
                .foregroundStyle(isEnabled ? palette.accent : palette.textTertiary)
        }
    }

    private var systemSettingsURL: URL? {
#if canImport(UIKit)
        URL(string: UIApplication.openSettingsURLString)
#else
        nil
#endif
    }
}
