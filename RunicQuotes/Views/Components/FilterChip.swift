//
//  FilterChip.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let palette: AppThemePalette
    let action: () -> Void

    var body: some View {
        Button(action: self.action) {
            Text(self.title)
                .font(DesignTokens.Typography.controlLabel)
                .foregroundStyle(self.isSelected ? self.palette.chipSelectedForeground : self.palette.textPrimary)
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background {
                    Capsule()
                        .fill(self.isSelected ? self.palette.chipSelectedFill : self.palette.chipFill)
                }
                .overlay {
                    Capsule()
                        .strokeBorder(
                            self.isSelected ? self.palette.strongCardStroke : self.palette.cardStroke,
                            lineWidth: DesignTokens.Stroke.hairline,
                        )
                }
        }
        .buttonStyle(.plain)
    }
}
