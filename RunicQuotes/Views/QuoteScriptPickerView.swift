//
//  QuoteScriptPickerView.swift
//  RunicQuotes
//
//  Created by Claude on 2026-03-13.
//

import SwiftUI

/// Script picker used on the home quote screen.
struct QuoteScriptPickerView: View {
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
        Picker("Runic Script", selection: selection) {
            ForEach(RunicScript.allCases) { script in
                Text(script.displayName).tag(script)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .accessibilityLabel("Runic script selector")
        .accessibilityValue(selectedScript.rawValue)
        .accessibilityHint("Select which runic script to display")
        .accessibilityIdentifier("quote_script_selector")
    }
}
