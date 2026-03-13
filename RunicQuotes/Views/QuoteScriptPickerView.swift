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
        EditorialCard(
            palette: palette,
            tone: .secondary,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: DesignTokens.Elevation.low,
            contentPadding: DesignTokens.Spacing.md
        ) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HeroHeader(
                    eyebrow: "Script",
                    title: selectedScript.displayName,
                    subtitle: "Choose the alphabet that shapes the current passage.",
                    meta: ["Visible on Home and widgets"],
                    palette: palette
                )

                GlassScriptSelector(selectedScript: selection)
                    .accessibilityLabel("Runic script selector")
                    .accessibilityValue(selectedScript.rawValue)
                    .accessibilityHint("Select which runic script to display")
                    .accessibilityIdentifier("quote_script_selector")
            }
        }
    }
}
