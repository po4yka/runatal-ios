//
//  LiquidActionCluster.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct LiquidActionCluster<Content: View>: View {
    let palette: AppThemePalette
    let spacing: CGFloat
    let content: Content

    init(
        palette: AppThemePalette,
        spacing: CGFloat = DesignTokens.Spacing.sm,
        @ViewBuilder content: () -> Content
    ) {
        self.palette = palette
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LiquidCard(
            palette: palette,
            role: .chrome,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: DesignTokens.Elevation.chrome,
            contentPadding: DesignTokens.Spacing.xs,
            interactive: true
        ) {
            HStack(spacing: spacing) {
                content
            }
        }
    }
}
