//
//  SettingsSectionHeaderView.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct SettingsSectionHeaderView: View {
    let title: String
    let icon: String
    let palette: AppThemePalette

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(palette.accent.opacity(0.4))
                .frame(width: 3, height: 20)

            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(palette.textSecondary)

            Text(title)
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            Spacer()
        }
    }
}
