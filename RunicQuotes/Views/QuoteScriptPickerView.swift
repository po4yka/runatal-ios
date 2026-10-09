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
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Spacing.sm) {
                        self.headerTitle.fixedSize(horizontal: true, vertical: false)
                        Spacer(minLength: DesignTokens.Spacing.sm)
                        self.widgetNote.fixedSize(horizontal: true, vertical: false)
                    }
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        self.headerTitle
                        self.widgetNote
                    }
                }

                GlassScriptSelector(selectedScript: self.selection)
                    .accessibilityLabel("Runic script selector")
                    .accessibilityValue(self.selectedScript.rawValue)
                    .accessibilityHint("Select which runic script to display")
                    .accessibilityIdentifier("quote_script_selector")
            }
        }
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
            SectionLabel(title: "Script", palette: self.palette)
            Text(self.selectedScript.displayName)
                .font(DesignTokens.Typography.pageTitle)
                .foregroundStyle(self.palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var widgetNote: some View {
        Text("Widgets follow this alphabet")
            .font(DesignTokens.Typography.metadata)
            .foregroundStyle(self.palette.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
