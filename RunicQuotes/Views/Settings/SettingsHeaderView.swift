//
//  SettingsHeaderView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct SettingsHeaderView: View {
    let palette: AppThemePalette

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Text("Settings")
                .font(.largeTitle.bold())
                .foregroundStyle(palette.textPrimary)

            Spacer()
        }
        .padding(.top, DesignTokens.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Settings")
        .accessibilityIdentifier("settings_header")
    }
}
