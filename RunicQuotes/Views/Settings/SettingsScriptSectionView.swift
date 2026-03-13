//
//  SettingsScriptSectionView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct SettingsScriptSectionView: View {
    let viewModel: SettingsViewModel
    let palette: AppThemePalette

    var body: some View {
        GlassCard(intensity: .medium) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SettingsSectionHeaderView(title: "Default Script", icon: "character.book.closed", palette: palette)

                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(RunicScript.allCases) { script in
                        scriptRow(script)

                        if script != RunicScript.allCases.last {
                            Rectangle()
                                .fill(palette.separator)
                                .frame(height: 1)
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings_script_section")
    }

    private func scriptRow(_ script: RunicScript) -> some View {
        let isSelected = viewModel.state.selectedScript == script
        let runicPreview = RunicTransliterator.transliterate("rune", to: script)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.updateScript(script)
            }
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Text(runicPreview)
                    .runicTextStyle(
                        script: script,
                        font: viewModel.state.selectedFont,
                        style: .body,
                        minSize: 16,
                        maxSize: 22
                    )
                    .foregroundStyle(palette.runeText)
                    .frame(width: 40, alignment: .center)

                Text(script.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.textPrimary)

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
        .accessibilityLabel("\(script.displayName) script")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityIdentifier("settings_script_\(script.rawValue)")
    }
}
