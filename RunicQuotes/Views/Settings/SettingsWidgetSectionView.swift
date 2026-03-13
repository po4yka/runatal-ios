//
//  SettingsWidgetSectionView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct SettingsWidgetSectionView: View {
    let viewModel: SettingsViewModel
    let palette: AppThemePalette

    var body: some View {
        GlassCard(intensity: .medium) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SettingsSectionHeaderView(title: "Widget", icon: "rectangle.on.rectangle", palette: palette)

                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(WidgetMode.allCases) { mode in
                        selectionRow(
                            title: mode.displayName,
                            subtitle: mode.description,
                            isSelected: viewModel.state.widgetMode == mode
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.updateWidgetMode(mode)
                            }
                        }
                        .accessibilityLabel("\(mode.displayName) mode")
                        .accessibilityValue(viewModel.state.widgetMode == mode ? "Selected" : "Not selected")
                        .accessibilityIdentifier("settings_widget_mode_\(mode.rawValue)")

                        if mode != WidgetMode.allCases.last {
                            Rectangle()
                                .fill(palette.separator)
                                .frame(height: 1)
                        }
                    }
                }

                Rectangle()
                    .fill(palette.separator)
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Widget Style")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textSecondary)

                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(WidgetStyle.allCases) { style in
                            selectionRow(
                                title: style.displayName,
                                subtitle: style.description,
                                isSelected: viewModel.state.widgetStyle == style
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.updateWidgetStyle(style)
                                }
                            }
                            .accessibilityLabel("\(style.displayName) style")
                            .accessibilityValue(viewModel.state.widgetStyle == style ? "Selected" : "Not selected")
                            .accessibilityIdentifier("settings_widget_style_\(style.rawValue.replacing(" ", with: "_"))")

                            if style != WidgetStyle.allCases.last {
                                Rectangle()
                                    .fill(palette.separator)
                                    .frame(height: 1)
                            }
                        }
                    }
                }

                Rectangle()
                    .fill(palette.separator)
                    .frame(height: 1)

                Toggle(isOn: widgetDecorativeGlyphsEnabled) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text("Decorative Glyph Identity")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(palette.textPrimary)

                        Text("Enable glyph ring and background pattern in widgets")
                            .font(.caption)
                            .foregroundStyle(palette.textTertiary)
                    }
                }
                .tint(palette.accent)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Widget settings")
        .accessibilityIdentifier("settings_widget_section")
    }

    private var widgetDecorativeGlyphsEnabled: Binding<Bool> {
        Binding(
            get: { viewModel.state.widgetDecorativeGlyphsEnabled },
            set: { viewModel.updateWidgetDecorativeGlyphsEnabled($0) }
        )
    }

    private func selectionRow(
        title: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
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

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.accent)
                        .font(.title3)
                        .accessibilityLabel("Selected")
                }
            }
            .padding(.vertical, DesignTokens.Spacing.xxs)
        }
        .buttonStyle(.plain)
    }
}
