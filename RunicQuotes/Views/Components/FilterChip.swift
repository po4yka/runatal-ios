//
//  FilterChip.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let palette: AppThemePalette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokens.Typography.controlLabel)
                .foregroundStyle(isSelected ? palette.chipSelectedForeground : palette.textPrimary)
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background {
                    Capsule()
                        .fill(isSelected ? palette.chipSelectedFill : palette.chipFill)
                }
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isSelected ? palette.strongCardStroke : palette.cardStroke,
                            lineWidth: DesignTokens.Stroke.hairline
                        )
                }
        }
        .buttonStyle(.plain)
    }
}
