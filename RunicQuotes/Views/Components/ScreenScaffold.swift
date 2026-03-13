//
//  ScreenScaffold.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct ScreenScaffold<Content: View>: View {
    let palette: AppThemePalette
    let scrollEnabled: Bool
    let horizontalPadding: CGFloat
    let topPadding: CGFloat
    let spacing: CGFloat
    let content: Content

    init(
        palette: AppThemePalette,
        scrollEnabled: Bool = true,
        horizontalPadding: CGFloat = DesignTokens.Spacing.md,
        topPadding: CGFloat = DesignTokens.Spacing.lg,
        spacing: CGFloat = DesignTokens.Spacing.xl,
        @ViewBuilder content: () -> Content
    ) {
        self.palette = palette
        self.scrollEnabled = scrollEnabled
        self.horizontalPadding = horizontalPadding
        self.topPadding = topPadding
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LiquidContentScaffold(
            palette: palette,
            scrollEnabled: scrollEnabled,
            horizontalPadding: horizontalPadding,
            topPadding: topPadding,
            spacing: spacing
        ) {
            content
        }
    }
}
