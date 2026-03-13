//
//  LiquidActionCluster.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

struct LiquidActionCluster<Content: View>: View {
    let palette: AppThemePalette
    let spacing: CGFloat
    let content: Content

    init(
        palette: AppThemePalette,
        spacing: CGFloat = DesignTokens.Spacing.sm,
        @ViewBuilder content: () -> Content,
    ) {
        self.palette = palette
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LiquidCard(
            palette: self.palette,
            role: .chrome,
            cornerRadius: DesignTokens.CornerRadius.xl,
            shadowRadius: DesignTokens.Elevation.chrome,
            contentPadding: DesignTokens.Spacing.xs,
            interactive: true,
        ) {
            HStack(spacing: self.spacing) {
                self.content
            }
        }
    }
}
