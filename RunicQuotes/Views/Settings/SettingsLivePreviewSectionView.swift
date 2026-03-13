//
//  SettingsLivePreviewSectionView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct SettingsLivePreviewSectionView: View {
    let viewModel: SettingsViewModel
    let palette: AppThemePalette

    var body: some View {
        SettingsPanel(
            palette: self.palette,
            tone: .hero,
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        SectionLabel(title: "Live Preview", palette: self.palette)
                        Text("Current atmosphere")
                            .font(DesignTokens.Typography.sectionTitle)
                            .foregroundStyle(self.palette.textPrimary)
                    }

                    Spacer()

                    Text(self.viewModel.state.selectedTheme.displayName)
                        .font(DesignTokens.Typography.listMeta)
                        .foregroundStyle(self.palette.textTertiary)
                }

                Text(self.viewModel.livePreviewRunicText)
                    .runicTextStyle(
                        script: self.viewModel.state.selectedScript,
                        font: self.viewModel.state.selectedFont,
                        style: .title2,
                        minSize: 22,
                        maxSize: 40,
                    )
                    .foregroundStyle(self.palette.runeText)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .center)

                Rectangle()
                    .fill(self.palette.separator)
                    .frame(height: 1)

                Text(self.viewModel.livePreviewLatinText)
                    .font(.callout)
                    .foregroundStyle(self.palette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack(spacing: DesignTokens.Spacing.sm) {
                    self.previewPill(label: "Script", value: self.viewModel.state.selectedScript.displayName)
                    self.previewPill(label: "Font", value: self.viewModel.state.selectedFont.displayName)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_live_preview")
    }

    private func previewPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            Text(label)
                .font(DesignTokens.Typography.listMeta)
                .foregroundStyle(self.palette.textTertiary)

            Text(value)
                .font(DesignTokens.Typography.controlLabel)
                .foregroundStyle(self.palette.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs)
        .background {
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                .fill(self.palette.bannerBackground)
        }
    }
}
