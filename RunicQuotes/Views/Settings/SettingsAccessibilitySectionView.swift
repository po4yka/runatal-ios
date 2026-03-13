//
//  SettingsAccessibilitySectionView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
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
        SettingsPanel(palette: self.palette) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SettingsSectionHeaderView(title: "Accessibility", icon: "accessibility", palette: self.palette)

                self.statusRow(
                    title: "Reduce Transparency",
                    subtitle: "Replaces glass effects with solid backgrounds",
                    isEnabled: self.reduceTransparency,
                )

                Rectangle()
                    .fill(self.palette.separator)
                    .frame(height: 1)

                self.statusRow(
                    title: "Reduce Motion",
                    subtitle: "Minimizes animations throughout the app",
                    isEnabled: self.reduceMotion,
                )

                Rectangle()
                    .fill(self.palette.separator)
                    .frame(height: 1)

                if let systemSettingsURL {
                    Button {
                        self.openURL(systemSettingsURL)
                    } label: {
                        HStack {
                            Text("Open System Settings")
                                .font(DesignTokens.Typography.controlLabel)
                                .foregroundStyle(self.palette.accent)

                            Spacer()

                            Image(systemName: "arrow.up.forward.app")
                                .font(.caption)
                                .foregroundStyle(self.palette.textTertiary)
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
                    .font(DesignTokens.Typography.supportingBody.weight(.medium))
                    .foregroundStyle(self.palette.textPrimary)

                Text(subtitle)
                    .font(DesignTokens.Typography.listMeta)
                    .foregroundStyle(self.palette.textTertiary)
            }

            Spacer()

            Text(isEnabled ? "On" : "Off")
                .font(DesignTokens.Typography.controlLabel)
                .foregroundStyle(isEnabled ? self.palette.accent : self.palette.textTertiary)
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
