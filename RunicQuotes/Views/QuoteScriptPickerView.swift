//
//  QuoteScriptPickerView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-13.
//

import SwiftUI

/// Script picker used on the home quote screen.
struct QuoteScriptPickerView: View {
    let palette: AppThemePalette
    let selectedScript: RunicScript
    let onSelect: (RunicScript) -> Void

    private var selection: Binding<RunicScript> {
        Binding(
            get: { selectedScript },
            set: { newScript in
                onSelect(newScript)
            }
        )
    }

    var body: some View {
        LiquidCard(
            palette: palette,
            role: .chrome,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: DesignTokens.Elevation.chrome,
            contentPadding: DesignTokens.Spacing.md
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        SectionLabel(title: "Script", palette: palette)
                        Text(selectedScript.displayName)
                            .font(DesignTokens.Typography.pageTitle)
                            .foregroundStyle(palette.textPrimary)
                    }

                    Spacer()

                    Text("Widgets follow this alphabet")
                        .font(DesignTokens.Typography.metadata)
                        .foregroundStyle(palette.textTertiary)
                }

                GlassScriptSelector(selectedScript: selection)
                    .accessibilityLabel("Runic script selector")
                    .accessibilityValue(selectedScript.rawValue)
                    .accessibilityHint("Select which runic script to display")
                    .accessibilityIdentifier("quote_script_selector")
            }
        }
    }
}
