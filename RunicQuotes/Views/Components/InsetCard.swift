//
//  InsetCard.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
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
        @ViewBuilder content: () -> Content,
    ) {
        self.palette = palette
        self.cornerRadius = cornerRadius
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        ContentPlate(
            palette: self.palette,
            tone: .secondary,
            cornerRadius: self.cornerRadius,
            shadowRadius: 0,
            contentPadding: self.contentPadding,
        ) {
            self.content
        }
    }
}
