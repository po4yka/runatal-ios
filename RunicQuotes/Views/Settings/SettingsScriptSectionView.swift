//
//  SettingsScriptSectionView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct SettingsScriptSectionView: View {
    let viewModel: SettingsViewModel
    let palette: AppThemePalette

    var body: some View {
        SettingsPanel(palette: self.palette) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                SettingsSectionHeaderView(title: "Default Script", icon: "character.book.closed", palette: self.palette)

                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(RunicScript.allCases) { script in
                        self.scriptRow(script)

                        if script != RunicScript.allCases.last {
                            Rectangle()
                                .fill(self.palette.separator)
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
        let isSelected = self.viewModel.state.selectedScript == script
        let runicPreview = RunicTransliterator.transliterate("rune", to: script)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.viewModel.updateScript(script)
            }
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Text(runicPreview)
                    .runicTextStyle(
                        script: script,
                        font: self.viewModel.state.selectedFont,
                        style: .body,
                        minSize: 16,
                        maxSize: 22,
                    )
                    .foregroundStyle(self.palette.runeText)
                    .frame(width: 40, alignment: .center)

                Text(script.displayName)
                    .font(DesignTokens.Typography.supportingBody.weight(.medium))
                    .foregroundStyle(self.palette.textPrimary)

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
        .accessibilityLabel("\(script.displayName) script")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityIdentifier("settings_script_\(script.rawValue)")
    }
}
