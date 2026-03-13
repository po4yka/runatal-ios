//
//  InsetCard.swift
//  RunicQuotes
//
//  Created by Codex on 2026-03-13.
//

import SwiftUI

struct InsetCard<Content: View>: View {
    let palette: AppThemePalette
    let cornerRadius: CGFloat
    let contentPadding: CGFloat
    let content: Content

    init(
        palette: AppThemePalette,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.lg,
        contentPadding: CGFloat = DesignTokens.Spacing.sm,
        @ViewBuilder content: () -> Content
    ) {
        self.palette = palette
        self.cornerRadius = cornerRadius
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        ContentPlate(
            palette: palette,
            tone: .secondary,
            cornerRadius: cornerRadius,
            shadowRadius: 0,
            contentPadding: contentPadding
        ) {
            content
        }
    }
}
