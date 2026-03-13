//
//  EditorialCard.swift
//  RunicQuotes
//
//  Created by Claude on 13.03.26.
//

import SwiftUI

enum EditorialCardTone {
    case hero
    case primary
    case secondary
}

struct EditorialCard<Content: View>: View {
    let palette: AppThemePalette
    let tone: EditorialCardTone
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let contentPadding: CGFloat
    let content: Content

    init(
        palette: AppThemePalette,
        tone: EditorialCardTone = .primary,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.xl,
        shadowRadius: CGFloat = DesignTokens.Elevation.medium,
        contentPadding: CGFloat = DesignTokens.Spacing.md,
        @ViewBuilder content: () -> Content,
    ) {
        self.palette = palette
        self.tone = tone
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.contentPadding = contentPadding
        self.content = content()
    }

    var body: some View {
        ContentPlate(
            palette: self.palette,
            tone: self.contentTone,
            cornerRadius: self.cornerRadius,
            shadowRadius: self.shadowRadius,
            contentPadding: self.contentPadding,
        ) {
            self.content
        }
    }

    private var contentTone: ContentPlateTone {
        switch self.tone {
        case .hero:
            .hero
        case .primary:
            .primary
        case .secondary:
            .secondary
        }
    }
}
