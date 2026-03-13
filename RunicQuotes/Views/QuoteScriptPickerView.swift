//
//  QuoteScriptPickerView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

/// Script picker used on the home quote screen.
struct QuoteScriptPickerView: View {
    let palette: AppThemePalette
    let selectedScript: RunicScript
    let onSelect: (RunicScript) -> Void

    private var selection: Binding<RunicScript> {
        Binding(
            get: { self.selectedScript },
            set: { newScript in
                self.onSelect(newScript)
            },
        )
    }

    var body: some View {
        LiquidCard(
            palette: self.palette,
            role: .chrome,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: DesignTokens.Elevation.chrome,
            contentPadding: DesignTokens.Spacing.md,
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        SectionLabel(title: "Script", palette: self.palette)
                        Text(self.selectedScript.displayName)
                            .font(DesignTokens.Typography.pageTitle)
                            .foregroundStyle(self.palette.textPrimary)
                    }

                    Spacer()

                    Text("Widgets follow this alphabet")
                        .font(DesignTokens.Typography.metadata)
                        .foregroundStyle(self.palette.textTertiary)
                }

                GlassScriptSelector(selectedScript: self.selection)
                    .accessibilityLabel("Runic script selector")
                    .accessibilityValue(self.selectedScript.rawValue)
                    .accessibilityHint("Select which runic script to display")
                    .accessibilityIdentifier("quote_script_selector")
            }
        }
    }
}
