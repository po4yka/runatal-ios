//
//  SettingsWidgetSectionView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI
import TipKit

struct SettingsWidgetSectionView: View {
    let viewModel: SettingsViewModel
    let palette: AppThemePalette
    let tipRefreshID: UUID

    var body: some View {
        GlassCard(intensity: .medium) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SettingsSectionHeaderView(title: "Widget", icon: "rectangle.on.rectangle", palette: self.palette)

                RunicInlineTip(
                    tip: SettingsWidgetConfigurationTip(),
                    palette: self.palette,
                    refreshID: self.tipRefreshID,
                    accessibilityIdentifier: "tip_settings_widget_configuration",
                )

                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(WidgetMode.allCases) { mode in
                        self.selectionRow(
                            title: mode.displayName,
                            subtitle: mode.description,
                            isSelected: self.viewModel.state.widgetMode == mode,
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                self.viewModel.updateWidgetMode(mode)
                            }
                            self.recordWidgetAdjustment()
                        }
                        .accessibilityLabel("\(mode.displayName) mode")
                        .accessibilityValue(self.viewModel.state.widgetMode == mode ? "Selected" : "Not selected")
                        .accessibilityIdentifier("settings_widget_mode_\(mode.rawValue)")

                        if mode != WidgetMode.allCases.last {
                            Rectangle()
                                .fill(self.palette.separator)
                                .frame(height: 1)
                        }
                    }
                }

                Rectangle()
                    .fill(self.palette.separator)
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Widget Style")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(self.palette.textSecondary)

                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(WidgetStyle.allCases) { style in
                            self.selectionRow(
                                title: style.displayName,
                                subtitle: style.description,
                                isSelected: self.viewModel.state.widgetStyle == style,
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    self.viewModel.updateWidgetStyle(style)
                                }
                                self.recordWidgetAdjustment()
                            }
                            .accessibilityLabel("\(style.displayName) style")
                            .accessibilityValue(self.viewModel.state.widgetStyle == style ? "Selected" : "Not selected")
                            .accessibilityIdentifier("settings_widget_style_\(style.rawValue.replacing(" ", with: "_"))")

                            if style != WidgetStyle.allCases.last {
                                Rectangle()
                                    .fill(self.palette.separator)
                                    .frame(height: 1)
                            }
                        }
                    }
                }

                Rectangle()
                    .fill(self.palette.separator)
                    .frame(height: 1)

                Toggle(isOn: self.widgetDecorativeGlyphsEnabled) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text("Decorative Glyph Identity")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(self.palette.textPrimary)

                        Text("Enable glyph ring and background pattern in widgets")
                            .font(.caption)
                            .foregroundStyle(self.palette.textTertiary)
                    }
                }
                .tint(self.palette.accent)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Widget settings")
        .accessibilityIdentifier("settings_widget_section")
    }

    private var widgetDecorativeGlyphsEnabled: Binding<Bool> {
        Binding(
            get: { self.viewModel.state.widgetDecorativeGlyphsEnabled },
            set: {
                self.viewModel.updateWidgetDecorativeGlyphsEnabled($0)
                self.recordWidgetAdjustment()
            },
        )
    }

    private func selectionRow(
        title: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void,
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(self.palette.textPrimary)

                    Text(subtitle)
                        .font(.caption)
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
    }

    private func recordWidgetAdjustment() {
        FeatureDiscoveryEvents.settingsAdjustedWidget.sendDonation()
        SettingsWidgetConfigurationTip().invalidate(reason: .actionPerformed)
    }
}
