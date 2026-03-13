//
//  SettingsSectionHeaderView.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct SettingsSectionHeaderView: View {
    let title: String
    let icon: String
    let palette: AppThemePalette

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(self.palette.accent.opacity(0.4))
                .frame(width: 3, height: 20)

            Image(systemName: self.icon)
                .font(.headline)
                .foregroundStyle(self.palette.textSecondary)

            Text(self.title)
                .font(.headline)
                .foregroundStyle(self.palette.textPrimary)

            Spacer()
        }
    }
}
