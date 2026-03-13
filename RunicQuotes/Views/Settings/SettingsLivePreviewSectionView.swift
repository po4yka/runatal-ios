//
//  SettingsLivePreviewSectionView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct SettingsLivePreviewSectionView: View {
    let viewModel: SettingsViewModel
    let palette: AppThemePalette

    var body: some View {
        GlassCard(intensity: .strong) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack {
                    Label("Live Preview", systemImage: "eye")
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    Spacer()

                    Text(viewModel.state.selectedTheme.displayName)
                        .font(.caption)
                        .foregroundStyle(palette.textTertiary)
                }

                Text(viewModel.livePreviewRunicText)
                    .runicTextStyle(
                        script: viewModel.state.selectedScript,
                        font: viewModel.state.selectedFont,
                        style: .title2,
                        minSize: 22,
                        maxSize: 40
                    )
                    .foregroundStyle(palette.runeText)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .center)

                Rectangle()
                    .fill(palette.separator)
                    .frame(height: 1)

                Text(viewModel.livePreviewLatinText)
                    .font(.callout)
                    .foregroundStyle(palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: DesignTokens.Spacing.sm) {
                    previewPill(label: "Script", value: viewModel.state.selectedScript.displayName)
                    previewPill(label: "Font", value: viewModel.state.selectedFont.displayName)
                }
            }
            .padding(DesignTokens.Spacing.xxs)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_live_preview")
    }

    private func previewPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Text(label)
                .font(.caption)
                .foregroundStyle(palette.textTertiary)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                .fill(.ultraThinMaterial)
                .opacity(0.35)
        }
    }
}
